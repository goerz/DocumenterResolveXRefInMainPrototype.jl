# DocumenterResolveXRefInMainPrototype

A prototype implementation of [Documenter PR #2470](https://github.com/JuliaDocs/Documenter.jl/pull/2470).

It tweaks the resolution of `@ref` links in docstrings to other docstrings. The current behavior is that the target of the link has to be available in the module that defines contains the `@ref` link. This prototype modifies that so that the target will also be resolved in `Main`, i.e., the `docs/make.jl` file.

## Installation

This package is not registered. See [Usage](#usage).


## Usage

In your `docs/make.jl` file, add

```
using Pkg
Pkg.add(url="https://github.com/goerz/DocumenterResolveXRefInMainPrototype.jl.git")

using DocumenterResolveXRefInMainPrototype
```

Note that this might modify, e.g., your `docs/Project.toml` file with the `DocumenterResolveXRefInMainPrototype` dependency. You should not commit that change.


> [!WARNING]
> This prototype is a "dirty hack" that monkeypatches Documenter.jl. Use at your own risk.
