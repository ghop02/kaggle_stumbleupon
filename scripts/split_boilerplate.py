import json, csv, re
from collections import defaultdict
f = open('../data/boilerplate.json', 'r')

drows = []
terms = set()


for l in f:
    d = defaultdict(int)
    splits = re.compile('[" ]').split(l.rstrip())
    for s in splits:
        if re.match('[0-9]+', s):
            continue
        if s == "":
            continue
        s = s.lower()
        terms.add(s)
        d[s] += 1.00001
    rows.append(splits)

print len(terms)
g = open('../data/words.csv', 'w')
g.write(','.join(sorted(list(terms))))
g.write('\n')

g = csv.DictWriter(open('../data/corpus.csv', 'w'), sorted(list(terms)), restval="1e-05")
for l in rows:
    g.writerow(l)
