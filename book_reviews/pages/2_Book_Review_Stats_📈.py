import pandas as pd
import numpy as np
import plotly.express as px
import streamlit as st
import book_functions as bf

# create list of file paths
paths = ['.data/book_reviews.csv.zip', '.data/titles_authors.csv.zip']

# set the outputs 
for path in paths:
    if 'book_reviews' in path:
        reviews = bf.read_zip_csv(path)
    else:
        book_titles = bf.read_zip_csv(path)

# from books_info, we only need the Title, authors, categories
books_info = book_titles[['Title', 'Author']]

# from reviews, we only need the Id, Title, User_id, and review/score
reviews = reviews[['Title', 'User_id', 'Categories', 'review/score']]

# fix the reviews Categories column to remove the [' and '] characters
reviews['Categories'] = reviews['Categories'].str.replace("[", '').str.replace("]", '').str.replace("'", '')

# join the two DataFrames on the Title and Author columns
book_reviews = pd.merge(books_info, reviews, on='Title')

# only keep the rows with complete data
book_reviews = book_reviews.dropna()

# create a new column for the author and title in the format 'Title by Author'
book_reviews['Title by Author'] = book_reviews['Title'] + ' by ' + book_reviews['Author']

# show scatterplot of top 100 reviewed books 
top_books = book_reviews.groupby('Title by Author').agg({'review/score': ['count', 'mean']})
top_books.columns = ['count', 'mean']
top_books = top_books.sort_values(by='count', ascending=False).head(100)

# show top 10 authors by count of reviews
top_authors = book_reviews.groupby('Author').agg({'review/score': ['count', 'mean']})
top_authors.columns = ['count', 'mean']
top_authors = top_authors.sort_values(by='count', ascending=False).head(10)

# for the top 10 authors get the Author, Title, Count of Reviews, Avg Score
top_author_books = book_reviews[book_reviews['Author'].isin(top_authors.index)]
top_author_books = top_author_books.groupby(['Author', 'Title']).agg({'review/score': ['count', 'mean']})
top_author_books.columns = ['count', 'mean']

# create new column ranking the books by count of reviews partition by author round to 0 decimal places
top_author_books['Rank'] = top_author_books.groupby('Author')['count'].rank(ascending=False, method='first').astype(str)
top_author_books_sorted = top_author_books.sort_values(by='count', ascending=False)

# show top 25 categories by count of reviews
top_categories = book_reviews.groupby('Categories').agg({'review/score': ['count', 'mean']})
top_categories.columns = ['count', 'mean']
top_categories = top_categories.sort_values(by='count', ascending=False).head(25)

# show top 100 books with categories not equal to Fiction, Juvenile Fiction, Juvenile Nonfiction, Young Adult Fiction
top_categories = top_categories[~top_categories.index.isin(['Fiction', 'Juvenile Fiction', 'Juvenile Nonfiction', 'Young Adult Fiction'])]

# get the top 100 books in these categories
top_non_fiction_books = book_reviews[book_reviews['Categories'].isin(top_categories.index)]
# get the top 100 books in these categories by count of reviews and avg score
top_non_fiction_books = top_non_fiction_books.groupby(['Title by Author', 'Categories']).agg({'review/score': ['count', 'mean']})
top_non_fiction_books.columns = ['count', 'mean']
top_non_fiction_books = top_non_fiction_books.sort_values(by='count', ascending=False).head(100)

# create tabs for the top 100 books by count of reviews, top 10 authors by count of reviews, and top 100 non-fiction books by count of reviews
tab1, tab2, tab3 = st.tabs(["Top 100 Books by Number of Reviews", 
                            "Top 10 Authors by Number of Reviews", 
                            "Top 100 Non-Fiction Books by Number of Reviews"])


with tab1:
    # show the top 100 books by count of reviews in a scatter plot
    fig = px.scatter(top_books, 
                    x='mean', 
                    y='count',
                    hover_name=top_books.index,
                    title='Top 100 Books by Number of Reviews')
    fig.update_layout(xaxis_title='Average Review Score', yaxis_title='Number of Reviews')
    st.plotly_chart(fig)

with tab2:
    # show the top_authors_books, with the x-axis being the author, the y-axis being the count of reviews but colored by the Title by Author in a bar chart
    fig = px.bar(top_author_books_sorted, 
                x=top_author_books_sorted.index.get_level_values(0), 
                y='count',
                color='Rank',
                hover_name=top_author_books_sorted.index.get_level_values(1),
                title='Top 10 Authors by Number of Reviews')
    fig.update_layout(xaxis_title='Author', yaxis_title='Number of Reviews')
    st.plotly_chart(fig)

with tab3:
    # show the top 100 non-fiction books by count of reviews
    fig = px.scatter(top_non_fiction_books, 
                    x='mean', 
                    y='count',
                    color=top_non_fiction_books.index.get_level_values(1),
                    hover_name=top_non_fiction_books.index.get_level_values(0),
                    title='Top 100 non-Fiction Books by Number of Reviews')
    fig.update_layout(xaxis_title='Average Review Score', yaxis_title='Number of Reviews')
    st.plotly_chart(fig)

# print a message explaining how to filter the data via the legends
st.info('''
            If you would like to filter by any values in the legend, simply double click the value on the legend.
            ''')    
