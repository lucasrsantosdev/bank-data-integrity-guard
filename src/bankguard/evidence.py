"""Evidência local de snapshots sintéticos. HMAC autentica manifesto, NÃO torna arquivos imutáveis."""
import hashlib
import hmac
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from .core import load_csv


def _digest(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def _canonical(obj):
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode('utf-8')


def _secret():
    key = os.environ.get('BANKGUARD_HMAC_KEY', '')
    if len(key.encode('utf-8')) < 32:
        raise ValueError('Defina BANKGUARD_HMAC_KEY com pelo menos 32 bytes, fora do Git')
    return key.encode('utf-8')


def capture(csv_path, manifest_path, key_field):
    csv_path, manifest_path = Path(csv_path), Path(manifest_path)
    columns, rows = load_csv(csv_path, key_field)
    payload = {
        'format_version': 1,
        'captured_at_utc': datetime.now(timezone.utc).isoformat(),
        'file_sha256': _digest(csv_path),
        'key_field': key_field,
        'columns': sorted(columns),
        'row_count': len(rows),
        'scope': 'local-demo-only',
    }
    tag = hmac.new(_secret(), _canonical(payload), hashlib.sha256).hexdigest()
    output = {'payload': payload, 'hmac_sha256': tag}
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    if manifest_path.exists():
        raise FileExistsError(f'Manifesto já existe: {manifest_path}. Não sobrescrever evidência.')
    manifest_path.write_text(json.dumps(output, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    return {'manifest': str(manifest_path), 'row_count': len(rows), 'sha256': payload['file_sha256']}


def verify(csv_path, manifest_path):
    data = json.loads(Path(manifest_path).read_text(encoding='utf-8'))
    payload, supplied = data['payload'], data['hmac_sha256']
    expected = hmac.new(_secret(), _canonical(payload), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, supplied):
        raise ValueError('Falha na autenticação do manifesto (HMAC)')
    if _digest(csv_path) != payload['file_sha256']:
        raise ValueError('Conteúdo CSV difere da evidência assinada')
    columns, rows = load_csv(csv_path, payload['key_field'])
    if sorted(columns) != payload['columns'] or len(rows) != payload['row_count']:
        raise ValueError('Contrato/schema ou quantidade inconsistente')
    return {'verified': True, 'row_count': len(rows), 'file_sha256': payload['file_sha256']}
