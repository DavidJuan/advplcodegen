# -*- coding: cp1252 -*-
import sys, os, settings, csv, shutil
import settings
from core.codeGenerators.codeGenerator import codeGenerator
from string import Template

class EntityListComponentHTMLGenerator(codeGenerator):

    def __init__ (self, entity=None):
        super().__init__(entity=None)
        self.templateFile = 'entity-list.component.html.template'
        self.templatePath = settings.PATH_TEMPLATE_PO_ENTITY_LIST
        self.srcPath = settings.PATH_PO_SRC_APP
        return

    def setFileOut(self):
        self.fileOut = ""
    
    def getVariables(self):
        sufixFileName = '-list.component.html'
        componentName = self.entity.namePortuguese.title().replace(" ","")
        componentNameLower = componentName.lower()
        componentCammelLower = componentName[:1].lower() + componentName[1:]
        
        self.fileOut = componentNameLower + sufixFileName
        self.srcPath = os.path.join(settings.PATH_PO_SRC_APP,componentNameLower.lower())
        self.srcPath = os.path.join(self.srcPath,componentNameLower.lower()+"-list")
        
        variables = {
                'componentNameLower' : componentNameLower,
                'componentCammelLower' : componentCammelLower
            }
        return variables

