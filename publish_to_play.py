#!/usr/bin/env python3
"""
Script para publicar AAB a Google Play desde línea de comandos.

Uso:
    python3 publish_to_play.py [track]

Tracks disponibles:
    internal    - Pruebas internas (default)
    alpha       - Alpha testing
    beta        - Beta testing
    production  - Producción

Ejemplo:
    python3 publish_to_play.py internal
    python3 publish_to_play.py production
"""

import os
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# Configuración
PACKAGE_NAME = "com.mergetowngame.app"
CREDENTIALS_FILE = os.path.join(os.path.dirname(__file__), "google-play-credentials.json")
AAB_FILE = os.path.join(os.path.dirname(__file__), "builds", "merge-town-release.aab")

# Scopes necesarios
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']


def get_service():
    """Crea el servicio de Google Play API."""
    credentials = service_account.Credentials.from_service_account_file(
        CREDENTIALS_FILE,
        scopes=SCOPES
    )
    return build('androidpublisher', 'v3', credentials=credentials)


def publish_aab(track='internal'):
    """Sube el AAB y lo publica al track especificado."""

    # Verificar archivos
    if not os.path.exists(CREDENTIALS_FILE):
        print(f"Error: No se encuentra {CREDENTIALS_FILE}")
        sys.exit(1)

    if not os.path.exists(AAB_FILE):
        print(f"Error: No se encuentra {AAB_FILE}")
        print("Genera el AAB primero desde Godot o ejecuta el workflow de GitHub.")
        sys.exit(1)

    print(f"Publicando a Google Play...")
    print(f"  Package: {PACKAGE_NAME}")
    print(f"  AAB: {AAB_FILE}")
    print(f"  Track: {track}")
    print()

    service = get_service()

    try:
        # 1. Crear un nuevo edit
        print("1. Creando edit...")
        edit = service.edits().insert(
            packageName=PACKAGE_NAME,
            body={}
        ).execute()
        edit_id = edit['id']
        print(f"   Edit ID: {edit_id}")

        # 2. Subir el AAB
        print("2. Subiendo AAB (esto puede tardar)...")
        media = MediaFileUpload(AAB_FILE, mimetype='application/octet-stream')
        upload = service.edits().bundles().upload(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            media_body=media
        ).execute()
        version_code = upload['versionCode']
        print(f"   Version code: {version_code}")

        # 3. Asignar al track
        # Usar 'draft' para apps no publicadas, 'completed' para apps publicadas
        release_status = 'draft' if track == 'internal' else 'completed'
        print(f"3. Asignando a track '{track}' (status: {release_status})...")
        service.edits().tracks().update(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            track=track,
            body={
                'track': track,
                'releases': [{
                    'versionCodes': [version_code],
                    'status': release_status
                }]
            }
        ).execute()
        print(f"   Asignado correctamente")

        # 4. Confirmar (commit) el edit
        print("4. Confirmando cambios...")
        service.edits().commit(
            packageName=PACKAGE_NAME,
            editId=edit_id
        ).execute()
        print("   Confirmado")

        print()
        print("=" * 50)
        print("PUBLICACION EXITOSA!")
        print(f"Version {version_code} publicada en track '{track}'")
        print("=" * 50)

        if track == 'internal':
            print("\nLos testers internos pueden actualizar desde Google Play.")
        elif track == 'production':
            print("\nGoogle revisará la app (1-3 días normalmente).")

    except Exception as e:
        print(f"\nError: {e}")
        sys.exit(1)


def main():
    tracks = ['internal', 'alpha', 'beta', 'production']

    # Obtener track del argumento
    if len(sys.argv) > 1:
        track = sys.argv[1].lower()
        if track not in tracks:
            print(f"Error: Track '{track}' no válido.")
            print(f"Tracks disponibles: {', '.join(tracks)}")
            sys.exit(1)
    else:
        track = 'internal'
        print(f"Usando track por defecto: {track}")
        print(f"(Puedes especificar otro: python3 publish_to_play.py production)")
        print()

    # Confirmar si es producción
    if track == 'production':
        print("ADVERTENCIA: Vas a publicar a PRODUCCION")
        response = input("¿Estás seguro? (s/N): ")
        if response.lower() != 's':
            print("Cancelado.")
            sys.exit(0)

    publish_aab(track)


if __name__ == '__main__':
    main()
