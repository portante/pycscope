import parser, token, symbol, sys, types, pprint

nodeNames = token.tok_name
nodeNames.update(symbol.sym_name)

def replaceNodeType(treeList):
    """Replaces the 0th element in the list with the name
    that corresponds to its node value.
    """
    # Replace node num with name
    treeList[0] = nodeNames[treeList[0]]

    # Recurse
    for i in range(1, len(treeList)):
        if type(treeList[i]) == types.ListType:
            replaceNodeType(treeList[i])

def main(fn="/Users/dwhall/Code/other/pyzeroconf-0.12/Browser.py"):
    """Returns a readable AST list for the given filename."""
    src = open(fn,'r').read()
    ast = parser.suite(src)
    lis = parser.ast2list(ast, True)
    replaceNodeType(lis)
    return lis

if __name__ == "__main__":
    pprint.pprint(main(sys.argv[-1]))
