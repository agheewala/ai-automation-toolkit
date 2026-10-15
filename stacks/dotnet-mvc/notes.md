# Stack Overlay: .NET Framework MVC (dotnet-mvc)

Hints for `generators/create-build-settings.prompt.md` and
`generators/create-coding-standards.prompt.md` when the target `CODE_ROOT` auto-detection finds:
- `.sln` + `.csproj` files targeting `net48`/`net45`/older (not SDK-style `net6.0`+)
- Razor `.cshtml` views
- `packages.config` (not `PackageReference`) NuGet style

Typical conventions to look for (confirm against the actual repo, do not assume):
- Build via `msbuild <Solution>.sln /p:Configuration=<Config> /p:Platform="Any CPU"` — NOT
  `dotnet build` (older .csproj format predates the `dotnet` CLI's full support).
- Module-per-solution-file layout (one `.sln` per business module, plus one root solution
  referencing all of them).
- `Html.c*`-style custom HTML helpers in place of raw `<input>`/`<select>` tags, if present.
- Theme-folder-per-brand CSS structure (`base/`, plus N theme variants), if present.
