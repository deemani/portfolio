import pandas as pd

# load the data
books_info = pd.read_csv('raw_data/books_info.csv')
reviews = pd.read_csv('raw_data/reviews_raw.csv')

# select the only the columns we need
# from books_info, we only need the Title, authors, categories
books_info = books_info[['Title', 'authors', 'categories']]
# from reviews, we only need the Id, Title, User_id, and review/score
reviews = reviews[['Id', 'Title', 'User_id', 'review/score']]

# rename the columns in books_info
books_info.columns = ['Title', 'Author', 'Categories']

# join the two DataFrames on the Title column
book_reviews = pd.merge(books_info, reviews, on='Title')

# only keep the rows with complete data
book_reviews = book_reviews.dropna()

# sort by title name
book_reviews = book_reviews.sort_values(by='Title')

# make a dataframe with only the distinct Title and Author combinations
titles = book_reviews[['Title', 'Author']].drop_duplicates()

# replace [' and '] in the Author values with nothing
titles['Author'] = titles['Author'].str.replace("[", '').str.replace("]", '').str.replace("'", '')

# need to make the title and author columns easy to search through
# removing stop words and some punctuation should help
# also change the text to lower case

title_characters_to_remove = ['a ', ' a ', 
                        'the ', ' the ', 
                        'of ', ' of ',
                        ' and ', 'and ',
                        ',', ';', ':']

author_characters_to_remove = ['.']


# Tolkien is a huge portion of the dataset but has multiple spellings so need to condense the two major discrepancies
# JRR Tolkien
# John Ronald Reuel Tolkien

# print all the distinct Author, Author_Clean pairs where Author_Clean has tolkien in it
print(titles[titles['Author_Clean'].str.contains('tolkien')][['Author', 'Author_Clean']].drop_duplicates())

# in the Titles column, wherever Author_Clean = 'johnronaldreueltolkien' then we will change Author = 'J. R. R. Tolkien'
titles.loc[titles['Author_Clean'] == 'johnronaldreueltolkien', 'Author'] = 'J. R. R. Tolkien'

# for loop that changes everything to lower case and replaces characters in the list above with nothing, and removes white space
# create 2 new columns as clean versions of Title and Author which will be what the search bar searches through
for character in title_characters_to_remove:
    titles['Title_Clean'] = titles['Title'].str.lower()
    titles['Title_Clean'] = titles['Title_Clean'].str.replace(character, '')
    titles['Title_Clean'] = titles['Title_Clean'].str.replace(' ', '')

for character in author_characters_to_remove:
    titles['Author_Clean'] = titles['Author'].str.lower()
    titles['Author_Clean'] = titles['Author_Clean'].str.replace(character, '')
    titles['Author_Clean'] = titles['Author_Clean'].str.replace(' ', '')

# export both to csv
titles.to_csv('clean_data/titles_authors.csv', index=False)
book_reviews.to_csv('clean_data/book_reviews.csv', index=False)