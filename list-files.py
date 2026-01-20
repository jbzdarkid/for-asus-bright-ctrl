from pathlib import Path

root = Path('.')
paths = []
for p in root.glob('**/*.*'):
  paths.append(str(p.resolve()))
paths.sort()
for p in paths:
  print(p)
