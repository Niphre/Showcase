import sys, os
import argparse

#toggles command and data parse debug print statements
debug = False

class Patron():
    def __init__(self):
        self.books = []
        self.borrowCount = 0

class Book():
    def __init__(self, title):
        self.title = title
        self.copies = 1
        self.borrowCount = 0

class Library():
    def __init__(self):
        self.patrons = {}
        self.books = {}
        self.outBooks = {}
        self.dupliPatrons = {}

        self.bookCount = 0
        self.checkOutCount = 0
        self.checkInCount = 0

    def loadFile(self, filename):
        with open(filename) as f:
            lines = f.readlines()
            for line in lines:
                command = line.partition(",")[0]
                data = line.partition(",")[2]

                if command.strip() == "addPatron":
                    self.addPatron(data)
                elif command.strip() == "removePatron":
                    self.removePatron(data)
                elif command.strip() == "addBook":
                    self.addBook(data)
                elif command.strip() == "removeBook":
                    self.removeBook(data)
                elif command.strip() == "checkin":
                    self.checkIn(data)
                elif command.strip() == "checkout":
                    self.checkOut(data)
                else:
                    print("Error: Command is invalad", file=sys.stderr)


    def addPatron(self, data):
        patronID = int(data.strip())

        if debug:
            print("adding patron with id:", patronID)
        
        if patronID in self.patrons:
            print("error, duplicate id, patron with id:", patronID, "already exists", file=sys.stderr)
        else:
            self.patrons.update({patronID : Patron()})
            self.dupliPatrons.update({patronID : Patron()})

    def removePatron(self, data):
        patronID = int(data.strip())

        if debug:
            print("removing patron with id:", patronID)

        if not patronID in self.patrons:
            print("error, patron with id:", patronID, "does not exist", file=sys.stderr)
        else:
            del self.patrons[patronID]
    
    def addBook(self, data):
        isbn = data.split(",")[0].strip()
        title = data.split(",")[1].strip()

        if debug:
            print("adding books with isbn:", isbn, "and title:", title)

        self.bookCount += 1

        if isbn in self.books:
            self.books[isbn].copies += 1
        else:
            self.books[isbn] = Book(title)

    def removeBook(self, data):
        isbn = data.strip()

        if debug:
            print("removing book with isbn:", isbn)

        if isbn in self.books:
            if self.books[isbn].copies == 1:
                del self.books[isbn]
                self.bookCount -= 1
            elif self.books[isbn].copies > 1:
                self.books[isbn].copies -= 1
                self.bookCount -= 1
            elif self.books[isbn].copies == 0:
                print("error, book with isbn", isbn, "is checked out and cannot be removed", file=sys.stderr)
        else:
            print("error, book with isbn:", isbn, "does not exist", file=sys.stderr)

    def checkOut(self, data):
        patronID = int(data.split(",")[0].strip())
        isbn = data.split(",")[1].strip()

        if debug:
            print("patron with id:", patronID, "checking out book with isbn:", isbn)

        if patronID in self.patrons:
            if isbn in self.books:
                if self.books[isbn].copies >= 1:
                    self.patrons[patronID].books.append(isbn)
                    self.books[isbn].copies -= 1
                    self.checkOutCount += 1
                    self.books[isbn].borrowCount += 1
                    self.dupliPatrons[patronID].borrowCount += 1
                else:
                    print("error, all copies of book with isbn:", isbn, "are checked out", file=sys.stderr)
            else:
                print("error, book with isbn:", isbn, "does not exist", file=sys.stderr)
        else:
            print("error, patron with id:", patronID, "does not exist", file=sys.stderr)
        

    def checkIn(self, data):
        patronID = int(data.split(",")[0].strip())
        isbn = data.split(",")[1].strip()

        if debug:
            print("patron with id:", patronID, "checking in book with isbn:", isbn)

        if patronID in self.patrons:
            if isbn in self.books:
                if isbn in self.patrons[patronID].books:
                    self.books[isbn].copies += 1
                    self.patrons[patronID].books.remove(isbn)
                    self.checkInCount += 1
                else:
                    print("error, book with isbn:", isbn, "has not been checked out by patron with id", patronID)
            else:
                print("error, book with isbn:", isbn, "does not exist", file=sys.stderr)
        else:
             print("error, patron with id:", patronID, "does not exist", file=sys.stderr)

    def getNumberOfBooks(self):
        return self.bookCount
    
    def getCheckOutCount(self):
        return self.checkOutCount

    def getCheckInCount(self):
        return self.checkInCount

    def getMostPopularBook(self):
        mostPopularISBN = ""
        mostPopularTitle = ""
        mostPopularCount = 0
        for isbn in self.books:
            if self.books[isbn].borrowCount > mostPopularCount:
                mostPopularISBN = isbn
                mostPopularTitle = self.books[isbn].title
                mostPopularCount = self.books[isbn].borrowCount
        return mostPopularISBN, mostPopularTitle, mostPopularCount
    
    def getMostPopularPatron(self):
        mostPopularPatronID = 0
        mostPopularPatronCount = 0
        for patronID in self.dupliPatrons:
            if self.dupliPatrons[patronID].borrowCount > mostPopularPatronCount:
                mostPopularPatronID = patronID
                mostPopularPatronCount = self.dupliPatrons[patronID].borrowCount
        return mostPopularPatronID, mostPopularPatronCount

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Lab 10')
    parser.add_argument('-i','--inputFileName', type=str, help='input file containing comma seperated command and data pairs', required=True)
    args = parser.parse_args()

    if not (os.path.isfile(args.inputFileName)):
	    print("error,", args.inputFileName, "does not exist, exiting.", file=sys.stderr)
	    exit(-1) 

    x = Library()
    x.loadFile(args.inputFileName)
    print(x.getNumberOfBooks())
    print(x.getCheckInCount())
    print(x.getCheckOutCount())
    a, b, c = x.getMostPopularBook()
    print(a, b, c, sep=", ")
    y, z = x.getMostPopularPatron()
    print(y, z, sep=", ")
