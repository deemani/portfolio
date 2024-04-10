import pandas as pd
import numpy as np
import streamlit as st
import plotly.express as px
import book_functions as bf

# the goal is to takes a user's input for a book title or author and returns a list of recommended books
# a user liking a book will be defined as a score >= 4
# the recommended books will be the top 10 books that users who liked the input book/author also liked
# the function which analyzes the data is in book_functions.py

# create the form for the user to input a search term
with st.form("book_recommendation_form"):
    st.subheader("Enter an author or book title:")
    
    search_type = st.radio("Search by author or book:",
             options=['Author', 'Book'], 
             horizontal=True)

    search_term = st.text_input("Search for...")
    
    submitted = st.form_submit_button("Submit")

# if the user presses submit
if submitted:
    # if search term is empty, whitepsace, is the term null, or is the term not a string, print a message to the user
    if search_term == '' or search_term.isspace() or search_term.lower() == 'null' or not isinstance(search_term, str):
        st.warning("Please enter a valid search term.", icon='🚨')
        st.stop()
    # else run the function to get recommended books
    else:
        # run function to get recommended books
        recommended_books = bf.process_search_term(search_term, search_type)
        
        # if no books are found, print an error message to the user
        if recommended_books.shape[0] == 0:
            st.warning(f"{search_type} not found in the data. Please try another search term.", icon='🚨')
            st.stop()
        else:
            # print the table of recommended books without the index
            st.subheader("Recommended Books:")
            st.dataframe(recommended_books, hide_index=True)

            # create chart of recommended books using maplotlib
            fig = px.bar(recommended_books, 
                         x='Title', 
                         y='Total Reviews', 
                         title='Top 10 Books Users Also Liked')
            fig.update_layout(xaxis_title='Book Title', 
                              yaxis_title='Number of Reviews')
            st.plotly_chart(fig)
            
       