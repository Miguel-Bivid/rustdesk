# BividDesk: marca y configuración

## Configuración del cliente (servidor, nombre, ajustes bloqueados)

El cliente acepta una configuración firmada (`custom.txt`, formato oficial de
RustDesk). Este fork verifica la firma con **nuestra** clave pública
(`custom_client.pub`) en lugar de la de RustDesk, y la configuración firmada se
incrusta en el binario al compilar (`build.rs` → `embed_custom_client`).

```
python branding/sign_custom_client.py genkey          # solo la primera vez
python branding/sign_custom_client.py sign branding/private/custom-full.json
python build.py --flutter
```

- `private/` no se sube a git: contiene la clave privada de firma, la
  configuración real y la salida firmada. **Guarda copia de `custom_client.sk`.**
- `custom-full.example.json` es la plantilla. Claves útiles:
  - `app-name`: nombre del producto (carpeta de config, servicio, instalación).
  - `override-settings`: valores forzados (`custom-rendezvous-server`,
    `relay-server`, `key`, `api-server`, `hide-*`...).
  - `default-settings`: valores iniciales que el usuario puede cambiar.
  - Claves de primer nivel (`conn-type`: `incoming` / `outgoing`, `disable-settings`...).
- `CUSTOM_CLIENT_FILE=<ruta>` permite compilar con otra configuración firmada
  (p. ej. la variante QuickSupport).

## Iconos

`icon.svg` (icono completo) y `glyph.svg` (símbolo blanco) son los originales.

```
pip install resvg-py pillow
python branding/gen_icons.py
```

Regenera `res/*` (ico/png de Windows, bandeja, Linux), `flutter/assets/icon.svg`,
el icono del runner de Windows y los mipmaps de Android.

## Tema

- Colores en `flutter/lib/common.dart` (`MyTheme`, `ColorThemeExtension`):
  morado Bivid `#7938AD`, magenta `#B53486`, grises de la web de Bivid.
- Tipografía Montserrat (OFL) en `flutter/assets/fonts/`, declarada en
  `flutter/pubspec.yaml`.
