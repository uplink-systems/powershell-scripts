# Sensitivity Labels

## Set-SensitivityLabelLocales.ps1

Microsoft's web interface for Sensitivity Labels supports to configure the label's display name and tooltip in a single language only. Localized display names and tooltips can be configured via PowerShell only. The <code>Set-SensitivityLabelLocales.ps1</code> script's purpose is to automate multilanguage settings.   

#### Parameter 'Labels'

The <code>Labels</code> parameter 

```
$Labels = @(
    @("P_01", @("en-us","de-de","es-es"), @("Public","Öffentlich","Público"), @("Public documents","Öffentliche Dokumente","Documentos públicos")),
    @("I_01", @("en-us","de-de","es-es"), @("Internal","Intern","Interno"), @("Internal documents","Interne Dokumente","Documentos internos"));
    @("C_01", @("en-us","de-de","es-es"), @("Confidential","Vertraulich","Confidencial"), @("Confidential documents","Vertrauliche Dokumente","Documentos confidenciales")),
    @("S_01", @("en-us","de-de","es-es"), @("Strictly confidential","Streng vertraulich","Estrictamente confidencial"), @("Strictly confidential documents","Streng vertrauliche Dokumente","Documentos estrictamente confidenciales"))
)
```

#### Executing the script

```
.\Set-SensitivityLabelLocales.ps1 -Labels $Labels
```
