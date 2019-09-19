# -*- coding: cp1252 -*-
import sys, os, settings, csv, shutil
from core.codeGenerators.codeGenerator import codeGenerator
from string import Template

class DefaultComponentHtmlGenerator(codeGenerator):

    def __init__ (self, entity=None, name=None, alias=None, shortName=None):
        super().__init__(entity=None, name=None, alias=None, shortName=None)
        self.templateFile = 'default.component.html.template'
        self.templatePath = settings.PATH_TEMPLATE_PO
        self.srcPath = settings.PATH_PO_SRC_APP
        return

    def setFileOut(self):
        self.fileOut = ""
    
    def getVariables(self,storagePathFile):
        sufixFileName = '.component.html'
        self.fileOut = self.namePortuguese.replace(" ","").lower() + sufixFileName
        self.srcPath = os.path.join(settings.PATH_PO_SRC_APP,self.namePortuguese.replace(" ","").lower())
        variables = {
                'ComponentName': self.namePortuguese, 
            }
        return variables
