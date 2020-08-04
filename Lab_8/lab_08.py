import argparse
import sys, os

class Node():
    def __init__(self, data, parent):
        self.data = data
        self.refcount = 1
        self.parent = parent
        self.left = None
        self.right = None
        

    
class BinarySearchTree():
    def __init__(self):
        self._root = None
        self._size = 0

    def __len__(self):
        return self._size

    def addOrIncrementDomainNameNode(self, data):
        if self._root == None:
            self._root = Node(data, None)
            self._size += 1 
        elif self._root.data == data:
            self._root.refcount += 1
        else:
            self.insertAtNode(self._root, data)
            
    def insertAtNode(self, node, data):
        if data < node.data:
            if node.left == None:
                node.left = Node(data, node)
                self._size += 1
            else:
                self.insertAtNode(node.left, data)
        elif data > node.data:
            if node.right == None:
                node.right = Node(data, node)
                self._size += 1
            else:
                self.insertAtNode(node.right, data)
        else:
            node.refcount += 1

    def printTree(self):
        self.inorder(self._root)

    def inorder(self, node):
        if node:
            self.inorder(node.left)
            print(node.data, node.refcount)
            self.inorder(node.right)
            

def read_file(tree, filename):
    with open(filename) as f:
        lines = f.readlines()
        for i in lines:
            tree.addOrIncrementDomainNameNode(i.split(':')[0])
    return len(lines)

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Lab 7 ')
    parser.add_argument('-i','--inputFileName', type=str, help='Apache server log output', required=True)
    args = parser.parse_args()

    if not (os.path.isfile(args.inputFileName)):
	    print("error,", args.inputFileName, "does not exist, exiting.", file=sys.stderr)
	    exit(-1) 

    x = BinarySearchTree()
    read_file(x, args.inputFileName)
    x.printTree()
