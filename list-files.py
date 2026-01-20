from pathlib import Path

root = Path('.')
for p in root.glob('**/*.*'):
  print(p.resolve())
