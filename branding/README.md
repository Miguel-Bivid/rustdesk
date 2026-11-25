# BividDesk: marca y configuración

## Configuración del cliente (servidor, nombre, ajustes bloqueados)

El cliente acepta una configuración firmada (`custom.txt`, formato oficial de
RustDesk). Este fork verifica la firma con **nuestra** clave pública
(`custom_client.pub`) en lugar de la de RustDesk, y la configuración firmada se
incrusta en el binario al compilar (`build.rs` → `embed_custom_client`).

```
python branding/sign_custom_client.py genkey          # solo la primera vez
python branding/sign_custom_client.py sign branding/private/custom-full.json
python build.py --flutter --hwcodec --vram
```

- `private/` no se sube a git: contiene la clave privada de firma, la
  configuración real y la salida firmada. **Guarda copia de `custom_client.sk`.**
- `custom-full.example.json` es la plantilla. Claves útiles:
  - `app-name`: nombre del producto (carpeta de config, servicio, instalación).
  - `override-settings`: valores forzados (`custom-rendezvous-server`,
    `relay-server`, `key`, `api-server`, `hide-*`...).
  - `default-settings`: valores iniciales que el usuario puede cambiar.
  - Claves de primer nivel (`conn-type`: `incoming` / `outgoing`, `disable-settings`...).
  - `privacy-url`, `terms-url` y `website-url` (primer nivel): política de
    privacidad ("Acerca de"), condiciones que se aceptan en la pantalla de
    instalación, y sitio web ("Acerca de"). Si falta una, ese enlace no se
    muestra; nunca apuntan a rustdesk.com.
  - `allow-auto-update: N` en `override-settings`: el actualizador de RustDesk
    instalaría el RustDesk oficial encima, sin nuestra configuración.
    `src/updater.rs` ya lo impide en el cliente personalizado; el override además
    deja fija la casilla "Actualización automática".
- `CUSTOM_CLIENT_FILE=<ruta>` permite compilar con otra configuración firmada
  (p. ej. la variante QuickSupport).

## Aviso de nueva versión

El actualizador de RustDesk está desactivado en el cliente personalizado. En su
lugar, si la configuración firmada trae `update-url` (clave de primer nivel), el
cliente descarga ese JSON al arrancar y, si hay una versión mayor que la suya,
muestra un aviso con un botón que abre la descarga en el navegador. No descarga
ni instala nada por sí mismo. Sin `update-url` no se consulta nada.

```json
{
  "windows": { "version": "1.5.1", "url": "https://SERVIDOR_WEB/bividdesk/BividDesk-1.5.1.exe" },
  "android": { "version": "1.5.1", "url": "https://SERVIDOR_WEB/bividdesk/BividDesk-1.5.1-arm64-v8a.apk" },
  "android-arm": { "version": "1.5.1", "url": "https://SERVIDOR_WEB/bividdesk/BividDesk-1.5.1-armeabi-v7a.apk" }
}
```

- La entrada `<so>-<arquitectura>` (`android-arm`, `android-x86_64`...) tiene
  prioridad sobre la de `<so>`. Las plataformas que no aparecen no reciben aviso.
- `update-url` y cada `url` deben ser `https://` con certificado válido.
- Publica el JSON **después** de subir los instaladores.
- El cliente personalizado no muestra la opción de buscar actualizaciones; para
  dejar de avisar, quita `update-url` y vuelve a firmar y compilar.

## Firma de código de Windows

`build.py` firma `BividDesk.exe` y las DLL antes de empaquetarlas (son lo que
queda instalado como servicio) y después el `BividDesk-<versión>.exe` final.
El comando de firma sale de `BIVIDDESK_SIGN_CMD`; los archivos se añaden al
final. Si no está definida, compila igualmente y avisa de que no hay firma; si
la firma falla, la compilación se detiene.

```powershell
# Certificado en token USB o almacén de Windows (por huella)
$env:BIVIDDESK_SIGN_CMD = '"C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" sign /fd sha256 /tr http://timestamp.digicert.com /td sha256 /sha1 HUELLA_DEL_CERTIFICADO'
# Azure Trusted Signing
$env:BIVIDDESK_SIGN_CMD = '"...\signtool.exe" sign /fd sha256 /tr http://timestamp.acs.microsoft.com /td sha256 /dlib C:\ruta\Azure.CodeSigning.Dlib.dll /dmdf C:\ruta\metadata.json'
python build.py --flutter --hwcodec --vram
```

Usa siempre sello de tiempo (`/tr`): sin él la firma deja de ser válida cuando
caduca el certificado.

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
