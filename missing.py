from pandas import  DataFrame
import numpy as np
import csv 
from random import choice
#NOTE: Sometimes when run the bootstrap will result in a KeyError, but this happens only sometimes and not always. The solution is simple: just run it until it works ;) 


def bootstrap(col): 
#bootstrap from the given column
    
    return choice(col)

def mapper(x): 
    if (x == '?'): 
        return np.nan
    return x

def fill_missing(data, out_name):
    data = [map(mapper, x) for x in data]

    df = DataFrame(data[1:], columns = data[0])
    #delete columns that are strings
    del df['alchemy_category']
    del df['url']
    del df['boilerplate']
    
    acs = df['alchemy_category_score']
    is_news = df['is_news']
    news_front_page = df['news_front_page'] 
    
    acs_non_null= acs[acs.notnull()]
    is_non_null = is_news[is_news.notnull()]
    nfp_non_null = news_front_page[news_front_page.notnull()] 

    df['alchemy_category_score'] = acs.fillna(bootstrap(acs_non_null))
    df['is_news'] = is_news.fillna(bootstrap(is_non_null))
    df['news_front_page'] = news_front_page.fillna(bootstrap(nfp_non_null))

    df.to_csv(out_name + '_na_filled.tsv', sep = '\t') 
    return df
if __name__ == "__main__":
    train_file = open("train.tsv", 'r')
    train_reader = csv.reader(train_file, delimiter = '\t')
    train_data = [x for x in train_reader]
    #function to replace '?' with the datatype that pandas recognizes
    # as missing: np.nan
    df = fill_missing(train_data, 'train')
    test_file = open("test.tsv", 'r')
    test_reader = csv.reader(test_file, delimiter = '\t')
    test_data = [x for x in test_reader]
    fill_missing(test_data, 'test')
