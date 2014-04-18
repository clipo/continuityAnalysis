__author__ = 'clipo'

import csv
from datetime import datetime
import operator
import argparse
import sys
import logging as logger
import itertools
import math
import random as rnd
import curses
from itertools import chain
import traceback
import collections
import operator
import time
from datetime import datetime
import os
import re
import numpy as np
import scipy as sp
import scipy.stats
import networkx as nx
import networkx.algorithms.isomorphism as iso
from pylab import *
import matplotlib.pyplot as plt
import matplotlib.mlab as mlab
import xlsxwriter
from networkx.algorithms.isomorphism.isomorph import graph_could_be_isomorphic as isomorphic


class continuityAnalysis():

    def __init__(self):
        pass

   def openFile(self, filename):
        try:
            logger.debug("trying to open: %s ", filename)
            file = open(filename, 'r')
        except csv.Error as e:
            logger.error("Cannot open %s. Error: %s", filename, e)
            sys.exit('file %s does not open: %s') % ( filename, e)

        reader = csv.reader(file, delimiter='\t', quotechar='|')
        values = []
        rowcount=0
        for row in reader:
            row = map(str, row)
            if rowcount==0 and self.args['noheader'] <> 1:
                rowcount=1
                row.pop(0)
                self.typeNames=row
            else:
                if len(row) > 1:
                    label = row[0]
                    self.labels.append(label)
                    row.pop(0)
                    row = map(float, row)
                    self.numberOfClasses = len(row)
                    freq = []
                    rowtotal = sum(row)
                    for r in row:
                        if self.args['occurrence'] not in self.FalseList:
                            if float(r)>0:
                                values.append(1)
                                freq.append(1)
                            else:
                                values.append(0)
                                freq.append(0)
                        else:
                            freq.append(float(float(r) / float(rowtotal)))
                            values.append(float(r))
                    self.assemblages[label] = freq
                    self.assemblageFrequencies[label] = freq
                    self.assemblageValues[label] = values
                    self.assemblageSize[label] = rowtotal
                    self.countOfAssemblages += 1
        self.maxSeriationSize = self.countOfAssemblages
        return True


    # from a "summed" graph, create a "min max" solution -- using Counts
    def createMinMaxGraphByCount(self, **kwargs):
        ## first need to find the pairs with the maximum occurrence, then we work down from there until all of the
        ## nodes are included
        ## the weight
        weight = kwargs.get('weight', "weight")
        input_graph = kwargs.get('input_graph')
        maxWeight = 0
        pairsHash = {}
        output_graph = nx.Graph(is_directed=False)

        for e in input_graph.edges_iter():
            d = input_graph.get_edge_data(*e)
            fromAssemblage = e[0]
            toAssemblage = e[1]
            if weight == "weight":
                currentWeight = int(d['weight'])
            else:
                currentWeight = int(d['weight'])
            pairsHash[fromAssemblage + "*" + toAssemblage] = currentWeight
            label = fromAssemblage + "*" + toAssemblage

        matchOnThisLevel = False
        currentValue = 0
        for key, value in sorted(pairsHash.iteritems(), key=operator.itemgetter(1), reverse=True):
            #print key, "->", value
            if value==0:
                value=.0000000000001
            if currentValue == 0:
                currentValue = value
            elif value < currentValue:
                matchOnThisLevel = False  ## we need to match all the connections with equivalent weights (otherwise we
                ## would stop after the nodes are included the first time which would be arbitrary)
                ## here we set the flag to false.
            ass1, ass2 = key.split("*")
            #print ass1, "-", ass2, "---",value
            if ass1 not in output_graph.nodes():
                output_graph.add_node(ass1, name=ass1, xCoordinate=self.xAssemblage[ass1],
                                      yCoordinate=self.yAssemblage[ass1], size=self.assemblageSize[ass1])
            if ass2 not in output_graph.nodes():
                output_graph.add_node(ass2, name=ass2, xCoordinate=self.xAssemblage[ass2],
                                      yCoordinate=self.yAssemblage[ass2], size=self.assemblageSize[ass2])
            if nx.has_path(output_graph, ass1, ass2) == False or matchOnThisLevel == True:
                matchOnThisLevel = True   ## setting this true allows us to match the condition that at least one match was
                ## made at this level

                output_graph.add_path([ass1, ass2], weight=value, inverseweight=(1/value ))

        return output_graph
