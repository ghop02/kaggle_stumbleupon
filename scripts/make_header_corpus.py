import csv, re, pprint, random, math, os, unicodecsv
from collections import defaultdict
random.seed(10010)

def splitFiles():
    f = csv.DictReader(open('part-00000.csv', 'r'))
    writers = {}
    fds = {}
    i = 0
    for l in f:
        i += 1
        if i % 500000 == 0:
            print i
        if l['key_1'] == "":
            continue

        fname = 'files/' + l['key_1'] + '.csv'
        if fname not in fds:
            fds[fname] = open(fname, 'w')
            writers[fname] = unicodecsv.writer(fds[fname])
        g = writers[fname]
        
        # array of keys Country | date | address | count
        values = [l['key_1'], l['key_0'], l['key_2'], l['value']]
        g.writerow(values)

    for g in fds.values():
        g.close()

def separateByCountry():
    f = csv.DictReader(open('part-00000.csv', 'r'))
    countries = defaultdict(list)
    i = 0
    for l in f:
        i += 1
        if i%100000 == 0:
            print "Read in {} entries".format(i)
        countries[l['key_1']].append(l)
    return countries

def splitCountry(f):
    all_keys = defaultdict(int)
    lines = []
    i = 0
    for l in f:
        i += 1
        if i % 100000 == 0:
            print "Country split progress: {}".format(i)

        # randomization 
        #if random.random() > count * 0.06:
        #    continue

        splits = re.compile(r'[?/(%2F)&=_ ]').split(l.rstrip())
        d = defaultdict(float)
        for sp in splits:
            sp = sp.lower()
            # upper and lowercase
            if re.search('([A-Z]+[a-z])|([a-z]+[A-Z])|([A-Z]+)', sp):
                continue
            # all capital letters
            if re.search('[A-Z]', sp):
                continue                
            if sp[:3] == "enc":
                continue
            
            s = sp
            if len(s) < 3:
                continue
            # alphanumeric match
            if re.match('(([A-Za-z]+[0-9])|([0-9]+[A-Za-z]))([A-Za-z]|[0-9])*', s):
                continue
            if re.match('\d+',s):
                continue
            if s in ['http:', 'l.php', 'http', 'ref', 'https:', 'site', 'sig', 'url']:
                continue
            for sp in re.compile(' ').split(s):
                a = ['a','able','about','across','after','all','almost','also','am','among','an','and','any','are','as','at','be','because','been','but','by','can','cannot','could','dear','did','do','does','either','else','ever','every','for','from','get','got','had','has','have','he','her','hers','him','his','how','however','i','if','in','into','is','it','its','just','least','let','like','likely','may','me','might','most','must','my','neither','no','nor','not','of','off','often','on','only','or','other','our','own','rather','said','say','says','she','should','since','so','some','than','that','the','their','them','then','there','these','they','this','tis','to','too','twas','us','wants','was','we','were','what','when','where','which','while','who','whom','why','will','with','would','yet','you','your']
                if sp.rstrip().lstrip() in a:
                    continue
                all_keys[s] += 1

                d[s] += 1 #count #1 #int(math.log(count)) + 1
        lines.append(d)

    n = 5000 if len(all_keys) >= 5000 else len(all_keys)
    top_n_keys_counts = [(v, k) for (k,v)
                         in sorted([(v,k)
                                    for k, v in all_keys.iteritems()], reverse=True)[:n]]
    top_n_keys = set([k for k,v in top_n_keys_counts])
    top_n_keys.add('count')
    # after we're finished aggregating everything, need to actually make rows
    folder = 'data/'

    if len(lines) < 5000:
        return
    print "number of lines : {}".format(len(lines))
    try:
        os.mkdir(folder)
    except:
        pass
        
    g = csv.DictWriter(open(folder + '/corpus.csv', 'w'), sorted(list(top_n_keys)), restval="1e-5")
    h = csv.DictWriter(open(folder + '/words.csv', 'w'), sorted(list(top_n_keys)))
    h.writeheader()
        

    print len(all_keys)
    print len(top_n_keys)

    top_n_keys = top_n_keys
    rows = []

    lines = random.sample(lines, 20000 if len(lines) > 20000 else len(lines))
    for l in lines:
#        for c in range(int(count)):
        #r = random.random()
        #if r < .01:
        d = {}
        for k, v in l.iteritems():
            if k not in top_n_keys:
                continue
            d[k] = v + 0.00001 #math.ceil(r*100*v) + 0.00001
        rows.append(d)
    g.writerows(rows)

#countries = separateByCountry()
#for country, items in countries.iteritems():
#    splitCountry(country, items)
#splitFiles()

#countries = ['NG', 'IN', 'ID', 'PH', 'BD', 'VN', 'KE', 'ZA', 'BR']
#for country in countries:
#    g = unicodecsv.DictReader(open('files/'+ country + '.csv', 'r'),
#                              fieldnames = ['key_1', 'key_0', 'key_2', 'value'])
#    splitCountry(country, g)

splitCountry(open('../Data/boilerplate.json', 'r'))