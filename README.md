# Mine Sweeper

A typescript and react version of mine sweeper.

![A completed game of Mine Sweeper, with every mine flagged and the timer stopped at 22 seconds](docs/screenshot.png)

## Get started

The component is developed and previewed in Storybook:

```
yarn storybook
```

## Develop

```
yarn test        # run the Vitest suite
yarn test:watch  # watch mode
yarn lint        # ESLint
yarn typecheck   # tsc --noEmit
yarn ts-build    # build the publishable library (dist/)
```

## Deploy

Releases are published to npm by CI via
[npm Trusted Publishing](https://docs.npmjs.com/trusted-publishers) (OIDC) — no
`NPM_TOKEN` secret, and provenance is attached automatically. Publishing is
triggered by publishing a GitHub Release for the version tag.

```
# 1. Make sure tests pass and the working tree is clean
yarn test

# 2. Add a CHANGELOG.md entry for the new version

# 3. Bump the version + create the git tag (patch / minor / major).
#    This updates package.json and creates a `vX.Y.Z` tag.
npm version patch

# 4. Push the commit and tag
git push --follow-tags

# 5. Publish the GitHub Release for the tag — this triggers the npm publish
gh release create vX.Y.Z --title vX.Y.Z --notes-file <notes>
```

> Note: the published library is built by `yarn ts-build`
> (`tsconfig.build.json`), which `prepublishOnly` runs automatically. Tests run
> on Vitest and Storybook builds with Vite.

The [publish workflow](.github/workflows/publish.yml) verifies that the release
tag matches `package.json`, and skips publishing if that version is already on
the registry, so re-runs are safe.

See [CHANGELOG.md](./CHANGELOG.md) for release notes.
