"""CLI determinística, sem acesso a redes, agentes ou LLMs."""
import argparse
import json
from pathlib import Path
from .core import compare
from .evidence import capture, verify


def main():
    parser = argparse.ArgumentParser(description='BankGuard: comparação e evidência de CSVs sintéticos')
    commands = parser.add_subparsers(dest='command', required=True)
    p = commands.add_parser('compare', help='R1 alteração, R2 inclusão, R3 exclusão')
    p.add_argument('before'); p.add_argument('after')
    p.add_argument('--key', required=True)
    p.add_argument('--before-manifest')
    p.add_argument('--after-manifest')
    p.add_argument('--output')
    p = commands.add_parser('capture', help='Criar manifesto HMAC, sem sobrescrever')
    p.add_argument('csv'); p.add_argument('manifest'); p.add_argument('--key', required=True)
    p = commands.add_parser('verify', help='Validar manifesto e bytes do CSV')
    p.add_argument('csv'); p.add_argument('manifest')
    args = parser.parse_args()
    if args.command == 'capture':
        result = capture(args.csv, args.manifest, args.key)
    elif args.command == 'verify':
        result = verify(args.csv, args.manifest)
    else:
        if bool(args.before_manifest) != bool(args.after_manifest):
            parser.error('Para comparar com evidências, informe ambos os manifestos')
        if args.before_manifest:
            verify(args.before, args.before_manifest)
            verify(args.after, args.after_manifest)
        result = compare(args.before, args.after, args.key)
        result['manifests_verified'] = bool(args.before_manifest)
        if args.output:
            destination = Path(args.output)
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
