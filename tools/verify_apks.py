"""Check the delivered APKs actually contain the current authored assets."""
from pathlib import Path
import zipfile,hashlib,json
root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/'assets/manifest.json').read_text(encoding='utf8'))
records=[]
for name in ['app-debug.apk','app-arm64-v8a-release.apk','app-x86_64-release.apk']:
    path=root/'build/app/outputs/flutter-apk'/name
    assert path.is_file(),path
    with zipfile.ZipFile(path) as z:
        names=z.namelist()
        assert not any('references/' in n for n in names)
        for a in manifest:
            raw=z.read('assets/flutter_assets/'+a['path'])
            assert hashlib.sha256(raw).hexdigest()==a['sha256'],a['path']
    records.append(dict(name=name,bytes=path.stat().st_size,
        sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
        asset_hashes_verified=len(manifest),references_excluded=True))
(root/'docs/evidence/apk_integrity.json').write_text(json.dumps(records,indent=2),encoding='utf8')
print(f'PASS: all {len(manifest)} current assets match SHA-256 inside each of 3 APKs; references excluded.')
