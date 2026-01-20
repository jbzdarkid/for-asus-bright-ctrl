from pathlib import Path

root = Path('.')
for p in root.glob('**/mfc140u.dll'):
  print(p)
