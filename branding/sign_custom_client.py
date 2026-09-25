#!/usr/bin/env python3
"""Genera la clave de firma y firma la configuracion de cliente personalizado.

  python branding/sign_custom_client.py genkey
  python branding/sign_custom_client.py sign branding/private/custom-full.json

Requiere: pip install pynacl
"""
import base64
import json
import sys
from pathlib import Path

from nacl.signing import SigningKey

HERE = Path(__file__).resolve().parent
PRIVATE = HERE / "private"
SECRET_KEY = PRIVATE / "custom_client.sk"
PUBLIC_KEY = HERE / "custom_client.pub"
OUT = PRIVATE / "out"


def genkey():
    if SECRET_KEY.exists():
        sys.exit(f"{SECRET_KEY} ya existe; no se sobrescribe")
    PRIVATE.mkdir(exist_ok=True)
    sk = SigningKey.generate()
    SECRET_KEY.write_text(base64.b64encode(bytes(sk)).decode())
    PUBLIC_KEY.write_text(base64.b64encode(bytes(sk.verify_key)).decode())
    print(f"Privada: {SECRET_KEY}  (NO subir a git, haz copia de seguridad)")
    print(f"Publica: {PUBLIC_KEY}")


def sign(src):
    src = Path(src)
    config = json.loads(src.read_text(encoding="utf-8-sig"))
    sk = SigningKey(base64.b64decode(SECRET_KEY.read_text().strip()))
    # Mismo formato que sodiumoxide sign::sign: firma(64) || mensaje
    signed = sk.sign(json.dumps(config, separators=(",", ":")).encode())
    OUT.mkdir(parents=True, exist_ok=True)
    dst = OUT / (src.stem + ".txt")
    dst.write_text(base64.b64encode(bytes(signed)).decode())
    print(f"Firmado: {dst}")


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "genkey":
        genkey()
    elif len(sys.argv) == 3 and sys.argv[1] == "sign":
        sign(sys.argv[2])
    else:
        sys.exit(__doc__)
