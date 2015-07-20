
'preprocessor test

#define FOO 1
#define BAR "bar"
#define dbl(X) ((X) * 2)

#If FOO == 1
Print dbl(FOO)    'prints 2
#Else
#  If 1
Print BAR
#  EndIf
#EndIf
