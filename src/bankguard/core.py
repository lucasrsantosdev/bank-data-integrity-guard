"""Comparação local e determinística de snapshots CSV sem dependências externas."""
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path

def load_csv(path, key):
    with open(path, encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if not reader.fieldnames or key not in reader.fieldnames:
            raise ValueError(f"Chave {key!r} ausente em {path}")
        if len(reader.fieldnames) != len(set(reader.fieldnames)):
            raise ValueError("Cabeçalhos duplicados")
        rows = {}
        for row in reader:
            if None in row or any(v is None for v in row.values()):
                raise ValueError("CSV com colunas inconsistentes")
            identity = row[key]
            if not identity or identity in rows:
                raise ValueError(f"Chave vazia ou duplicada: {identity!r}")
            rows[identity] = row
        return set(reader.fieldnames), rows

def fingerprint(row):
    canonical = json.dumps(row, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()

def compare(before, after, key):
    columns_old, a = load_csv(before, key)
    columns_new, b = load_csv(after, key)
    if columns_old != columns_new:
        raise ValueError("Schema divergente: comparar somente após validação/aprovação do contrato")
    modified = []
    for identity in sorted(a.keys() & b.keys()):
        if fingerprint(a[identity]) != fingerprint(b[identity]):
            changed = sorted(k for k in columns_old if a[identity][k] != b[identity][k])
            modified.append({"key": identity, "changed_fields": changed,
                             "before_hash": fingerprint(a[identity]), "after_hash": fingerprint(b[identity])})
    inserted = sorted(b.keys() - a.keys())
    deleted = sorted(a.keys() - b.keys())
    return {"key_field": key, "before_count": len(a), "after_count": len(b),
            "R1_modified": modified, "R2_inserted_keys": inserted,
            "R3_deleted_keys": deleted, "unchanged_count": len(a.keys() & b.keys()) - len(modified),
            "warning": "Divergência não comprova fraude; snapshots não revelam mudanças intermediárias. Não contém PII."}
