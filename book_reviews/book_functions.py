import pandas as pd 
import numpy as np
import zipfile

# function to open and unzip large csv file
def read_zip_csv(zip_file_path):
    # ppen the ZIP file
    with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
        # extract it
        zip_info = zip_ref.infolist()[0]
        # extract the file to a temporary location
        zip_ref.extract(zip_info)
        #rRead the extracted file into a DataFrame
        df = pd.read_csv(zip_info.filename)
    
    return df

# create a function that takes in a search term and search type and returns a DataFrame of recommended books
def process_search_term(search_term, search_type):

    # create list of file paths
    paths = ['.data/book_reviews.csv.zip', '.data/titles_authors.csv.zip']
    # set the outputs 
    for path in paths:
        if 'book_reviews' in path:
            reviews = read_zip_csv(path)
        else:
            book_titles = read_zip_csv(path)

    # fix the Author column to remove the [' and '] around the author names
    reviews['Author'] = reviews['Author'].str.replace("['", '').str.replace("']", '')
    reviews['Categories'] = reviews['Categories'].str.replace("['", '').str.replace("']", '')

    # clean up the search term to make it easier to search through the data
    search_term = search_term.lower()
    search_term = search_term.replace('.', '')
    search_term = search_term.replace(' ', '')
    
    # if the search term is an author
    if search_type == 'Author':
        # get the distinct Titles where search term is in Author_Clean
        author_books = book_titles[book_titles['Author_Clean'].str.contains(search_term, na = False)]['Title'].unique()
        
        # get the users who positively reviewed these books,s core >= 4
        positive_reviewers = reviews[reviews['Title'].isin(author_books)]['User_id'].unique()

        # check what books the other than the books in author_books the positive reviewers liked, round to the 2nd decimal place
        recommended_books = reviews[reviews['User_id'].isin(positive_reviewers)].groupby(['Title', 'Author', 'Categories']).agg({'review/score': ['count', 'mean']})

        # remove the books that are in author_books
        recommended_books = recommended_books.drop(author_books, errors='ignore')

    else:
        # get all the books in book_titles Titles_Clean column that contains the search term
        books = book_titles[book_titles['Title_Clean'].str.contains(search_term, na = False)]['Title'].unique()
        
        # get every distinct user who positively reviewed the books
        positive_reviewers = reviews[reviews['Title'].isin(books)]['User_id'].unique()

        # get the books that the positive reviewers liked, round to the 2nd decimal place, order by count and then average score
        recommended_books = reviews[reviews['User_id'].isin(positive_reviewers)].groupby(['Title', 'Author', 'Categories']).agg({'review/score': ['count', 'mean']})
        
        # remove the books that are in books
        recommended_books = recommended_books.drop(books, errors='ignore')
    
    # regardless of search type, we need to do the following
    # round the score to 2 decimal places
    recommended_books[('review/score', 'mean')] = np.round(recommended_books[('review/score', 'mean')], 2)

    # only keep the books with a score >= 4
    recommended_books = recommended_books[recommended_books[('review/score', 'mean')] >= 4]

    # sort by the count of reviews and then the average score
    recommended_books = recommended_books.sort_values(by=('review/score', 'count'), ascending=False).head(10)

    # rename the columns Total Reviews, Average Score
    recommended_books.reset_index(inplace=True)
    recommended_books.columns = ['Title', 'Author', 'Category', 'Total Reviews', 'Average Score']
        
    return recommended_books
        
