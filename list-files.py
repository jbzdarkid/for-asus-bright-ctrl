from pathlib import Path

root = Path('.')
for p in root.glob('**/mfc140u.dll'):
  print(p)
p = Path(r'C:\Program Files\Microsoft Visual Studio\2022\Enterprise')
print(p.exists())

paths = [(q.name, str(q.resolve())) for q in p.glob('**/*.dll')]
paths.sort()
for p in paths:
  print(p)
