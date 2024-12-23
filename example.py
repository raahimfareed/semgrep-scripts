import sqlite3
import os

SECRET_KEY = "9Ds7mnA0wa8v3NmSI47dmA=="

def insecure_sql_query(user_input):
    connection = sqlite3.connect("test.db")
    cursor = connection.cursor()
    query = f"SELECT * FROM users WHERE username = '{user_input}';"
    cursor.execute(query)
    results = cursor.fetchall()
    connection.close()
    return results

def insecure_eval(user_input):
    return eval(user_input)

def main():
    print("Welcome to the vulnerable application!")

    user_input = input("Enter username to search: ")
    results = insecure_sql_query(user_input)
    print("Query Results:", results)

    eval_input = input("Enter Python code to evaluate: ")
    eval_result = insecure_eval(eval_input)
    print("Eval Result:", eval_result)

if __name__ == "__main__":
    main()
