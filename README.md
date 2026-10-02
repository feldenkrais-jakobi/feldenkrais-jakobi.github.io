# fjakobi-site

Hakyll site for the Feldenkrais practice of Heinrich Jakobi.

## Editing content

- **Termine (appointments):** edited via [Pages CMS](https://app.pagescms.org).
  See the how-to guide: [docs/termine-anleitung.md](docs/termine-anleitung.md).

## Development

```
nix develop
cabal run fjakobi-site -- watch
```

## Build

```
nix build .#website
```

## License

GPL-3.0-only; see [LICENSE](LICENSE). This site bundles the YOOtheme
Aurora template (GPL-3.0); see [THIRD-PARTY.md](THIRD-PARTY.md).
