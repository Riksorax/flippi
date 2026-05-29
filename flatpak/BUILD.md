# Flippi Flatpak Build

## Voraussetzungen

```bash
sudo apt install flatpak-builder
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08
```

## Vor dem ersten Build

1. **Icon erstellen:** `flatpak/icons/512x512/io.github.frankspeu.flippi.png` (512×512 PNG)

2. **SHA256-Checksums eintragen** in `io.github.frankspeu.flippi.yml`:
   ```bash
   # wl-clipboard:
   wget https://github.com/bugaevc/wl-clipboard/archive/refs/tags/v2.2.1.tar.gz
   sha256sum v2.2.1.tar.gz

   # keybinder:
   wget https://github.com/kupferlauncher/keybinder/releases/download/keybinder-3.0-v0.3.2/keybinder-3.0-0.3.2.tar.gz
   sha256sum keybinder-3.0-0.3.2.tar.gz
   ```

## Build

```bash
# 1. Flutter Release Build
flutter build linux --release

# 2. Flatpak bauen (aus Projektroot)
flatpak-builder --force-clean build-dir flatpak/io.github.frankspeu.flippi.yml

# 3. Lokal testen
flatpak-builder --run build-dir flatpak/io.github.frankspeu.flippi.yml flippi
```

## Flathub Submission

1. GitHub Repo `github.com/Riksorax/flippi` mit dem Code erstellen
2. Screenshots für AppStream hinzufügen
3. Flathub PR: https://github.com/flathub/flathub (neues Repo beantragen)
