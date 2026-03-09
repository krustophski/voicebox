# Voicebox Session State

Last updated: 2026-03-09

## Repository

- Local repo: `C:\Users\post\vscode\voicebox`
- Git branch: `feature/web-full-interface`
- Fork remote: `origin = https://github.com/krustophski/voicebox.git`
- Upstream remote: `upstream = https://github.com/jamiepine/voicebox`

## Installed app and data

- Desktop app: `C:\Users\post\AppData\Local\Voicebox\voicebox.exe`
- Bundled backend: `C:\Users\post\AppData\Local\Voicebox\voicebox-server.exe`
- Data directory with models, voices, DB, generated audio:
  `C:\Users\post\AppData\Local\Voicebox`

## Current behavior

- Desktop shortcut `C:\Users\post\Desktop\Voicebox.lnk` was repointed.
- Now one click on `Voicebox.lnk` should:
  - launch the normal desktop app
  - start the backend server if needed
  - start the web interface for LAN access

## LAN access

- Web URL on this machine: `http://127.0.0.1:5173`
- Web URL from local network: `http://192.168.1.111:5173`
- Backend URL from local network: `http://192.168.1.111:17493`
- API docs: `http://192.168.1.111:17493/docs`

## Important files changed

- Launcher script:
  [scripts/start-voicebox-web.ps1](C:/Users/post/vscode/voicebox/scripts/start-voicebox-web.ps1)
- Web Vite config:
  [web/vite.config.ts](C:/Users/post/vscode/voicebox/web/vite.config.ts)
- Web LAN backend env:
  `web/.env.local`
- Theme toggle:
  [app/src/components/ThemeToggle.tsx](C:/Users/post/vscode/voicebox/app/src/components/ThemeToggle.tsx)
- Theme state:
  [app/src/stores/uiStore.ts](C:/Users/post/vscode/voicebox/app/src/stores/uiStore.ts)

## Web launcher details

The launcher script:

- detects the current LAN IP automatically
- keeps backend on `0.0.0.0:17493`
- restarts the web dev server on `0.0.0.0:5173`
- injects `VITE_SERVER_URL=http://<LAN_IP>:17493`
- launches the normal desktop app

## Manual commands

Backend only:

```powershell
& "C:\Users\post\AppData\Local\Voicebox\voicebox-server.exe" --host 0.0.0.0 --port 17493 --data-dir "C:\Users\post\AppData\Local\Voicebox"
```

Web only:

```powershell
cd C:\Users\post\vscode\voicebox\web
& "C:\Users\post\AppData\Local\Microsoft\WinGet\Packages\Oven-sh.Bun_Microsoft.Winget.Source_8wekyb3d8bbwe\bun-windows-x64\bun.exe" run dev
```

All-in-one:

```powershell
& "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "C:\Users\post\vscode\voicebox\scripts\start-voicebox-web.ps1"
```

## Build status

- `bun run build:web` passes
- `app` build passes

## UI changes already implemented

- Shared web UI uses the app frontend
- Browser audio output routing support added where browser supports `setSinkId`
- Persistent light/dark theme toggle added
- LAN web startup configured

## Known limitations

- Internet exposure is not finished safely yet.
- Current LAN web is based on Vite dev server, suitable for local network testing, not for hardened public hosting.
- `web/.env.local` is gitignored, so LAN backend URL is local-machine-specific.

## Resume notes

If continuing later, read this file first and verify:

1. `Voicebox.lnk` still points to PowerShell launcher, not directly to `voicebox.exe`
2. LAN IP has not changed from `192.168.1.111`
3. Backend health responds on `/health`
4. Web responds on port `5173`

If LAN IP changes, update:

- `web/.env.local`
- any manual URLs given to other devices
