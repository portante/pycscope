import parser, token, symbol, sys, types, pprint

nodeNames = token.tok_name
nodeNames.update(symbol.sym_name)

def replaceNodeType(treeList):
    """ Replaces the 0th element in the list with the name
        that corresponds to its node value.
    """
    # Replace node num with name
    treeList[0] = nodeNames[treeList[0]]

    # Recurse
    for i in range(1, len(treeList)):
        if type(treeList[i]) == types.ListType:
            replaceNodeType(treeList[i])

def main(fn=""):
    """ Returns a readable (c)oncrete (s)yntax (t)ree (CST)
        list for the given filename.
    """
    if not fn: return []
    src = open(fn,'r').read()
    cst = parser.suite(src)
    lis = parser.st2list(cst, True)
    replaceNodeType(lis)
    return lis

if __name__ == "__main__":
    pprint.pprint(main(sys.argv[-1]))
