import numpy as np
from sklearn.ensemble import RandomForestClassifier
if __name__ == "__main__":
    train_data = np.genfromtxt('train_na_filled.tsv', delimiter = '\t', skip_header = 1)
    train = train_data[:, :24]
    labels = train_data[:,24]
    test_data = np.genfromtxt('test_na_filled.tsv', delimiter = '\t', skip_header = 1)
    clf = RandomForestClassifier(n_estimators = 50)
    clf.fit(train,labels)
    predictions = clf.predict(test_data)
    #add urlids
    urlids = test_data[:, 0]
    length = len(urlids) 
    file_out = open("predictions", "w")
    file_out.write('urlid,label' + '\n') 
    for num in xrange(length):
        file_out.write(str(int(urlids[num])) + ',' + str(int(predictions[num])) + '\n')

    file_out.close()
