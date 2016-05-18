You're interested in contributing to this project, that's awesome!

## Dependencies

We are using [Carthage](https://github.com/Carthage/Carthage) to manage dependencies without relying on it at build-time by integrating dependencies as Git Submodules. If you want to update a dependency, please change the corresponding `Cartfile` and run:

```sh
carthage update --use-submodules --no-build <dependency>
```
