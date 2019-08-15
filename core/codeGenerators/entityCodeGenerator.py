# -*- coding: cp1252 -*-
import sys, os, settings, csv, shutil
from core.codeGenerators.codeGenerator import codeGenerator
from string import Template

class entityCodeGenerator(codeGenerator):

    def __init__ (self, entity=None, name=None, alias=None, shortName=None):
        super().__init__(entity=None, name=None, alias=None, shortName=None)
        self.templateFile = 'Entity.template' 
        self.srcPath = settings.PATH_SRC_ENTITY
        return

    def setFileOut(self):
        self.fileOut = self.prefix+self.shortName + ".prw"
    
    def getVariables(self,storagePathFile):
        serialize = ''
        fields    = ''
        with open(storagePathFile) as datafile:
            columnInfo = csv.reader(datafile, delimiter=';')
            for column in columnInfo:
                serialize   += '    oJsonControl:setProp(oJson,"' + column[1] + '",self:getValue("'+ column[1]+'")) /* Column '+ column[0] +' */ \n'
                fields      += '    self:oFields:push({"'+column[1]+'", self:getValue("'+column[1] +'")}) /* Column '+ column[0] +' */ \n'
                
            variables = { 
                    'className': self.shortName, 
                    'description': self.name, 
                    'serialize' : serialize,
                    'fields' : fields,
                    'entity' : self.entity,
                    'prefix' : self.prefix,
                }
        return variables