module DocumenterResolveXRefInMainPrototype

import MarkdownAST
using Documenter: Documenter, find_object
import Documenter: docsxref


# This overwrites Documener.docsxref by making annotating `code` as
# `AbstractString`, which makes the method more precise, overwriting the
# default implementation

function docsxref(node::MarkdownAST.Node, code::AbstractString, meta, page, doc, errors)
    @debug "Resolving @ref for $(repr(code)) with prototype #2470"
    @assert node.element isa MarkdownAST.Link
    # Add the link to list of local uncheck links.
    doc.internal.locallinks[node.element] = node.element.destination
    if haskey(meta, :CurrentModule)
        modules = [meta[:CurrentModule], Main]
    else
        modules = [Main]
    end
    for mod in modules
        docref = find_docref(code, mod, page)
        if haskey(docref, :error)
            # We'll bail if the parsing of the docref wasn't successful
            msg = "Exception trying to find docref for `$code`: $(docref.error)"
            @debug msg exception = docref.exception  # shows the full backtrace
            push!(errors, msg)
        else
            binding, typesig = docref
            # Try to find a valid object that we can cross-reference.
            object = find_object(doc, binding, typesig)
            if object !== nothing
                # Replace the `@ref` url with a path to the referenced docs.
                docsnode = doc.internal.objects[object]
                slug = Documenter.slugify(object)
                pagekey = relpath(docsnode.page.build, doc.user.build)
                page = doc.blueprint.pages[pagekey]
                node.element = Documenter.PageLink(page, slug)
                break  # stop after first mod with binding we can link to
            else
                msg = "no docstring found in doc for binding $(binding.mod).$(binding.var)."
                push!(errors, msg)
            end
        end
    end
end

function find_docref(code, mod, page)
    # Parse the link text and find current module.
    keyword = Symbol(strip(code))
    local ex
    if haskey(Docs.keywords, keyword)
        ex = QuoteNode(keyword)
    else
        try
            ex = Meta.parse(code)
        catch err
            isa(err, Meta.ParseError) || rethrow(err)
            return (error = "unable to parse the reference `$code` in $(Documenter.locrepr(page.source)).", exception = nothing)
        end
    end

    # Find binding and type signature associated with the link.
    local binding
    try
        binding = Documenter.DocSystem.binding(mod, ex)
    catch err
        return (
            error = "unable to get the binding for `$code` in module $(mod)",
            exception = (err, catch_backtrace()),
        )
        return
    end

    local typesig
    try
        typesig = Core.eval(mod, Documenter.DocSystem.signature(ex, rstrip(code)))
    catch err
        return (
            error = "unable to evaluate the type signature for `$code` in $(Documenter.locrepr(page.source)) in module $(mod)",
            exception = (err, catch_backtrace()),
        )
    end

    return (binding = binding, typesig = typesig)
end

end # module DocumenterResolveXRefInMainPrototype
