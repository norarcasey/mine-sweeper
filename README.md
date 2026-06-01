# Mine Sweeper

A typescript and react version of mine sweeper.

## Get started

```
yarn storybook
```

## Deploy

Releases are published to npm. The steps below build the library (`dist/`)
from source, tag the release, and publish it.

```
# 1. Make sure tests pass and the working tree is clean
npm test -- --watchAll=false

# 2. Add a CHANGELOG.md entry for the new version

# 3. Bump the version + create the git tag (patch / minor / major).
#    This updates package.json and creates a `vX.Y.Z` tag.
npm version patch

# 4. Publish (prepublishOnly rebuilds dist/ from tsconfig.build.json)
npm publish

# 5. Push the commit and tag
git push --follow-tags
```

> Note: `npm run build` is the Create React App **app** build and is not used
> for publishing. The published library is built by `npm run ts-build`
> (`tsconfig.build.json`), which `prepublishOnly` runs automatically.

See [CHANGELOG.md](./CHANGELOG.md) for release notes.
