## Custom Compliance

The custom compliance detection script and the rules file check for requirements that I use in my daily business.  
  
### check if non-default accounts are member of local administrators group
  
Approved members are in this case (must be modified to your needs):  
- the built-in local administrator account  
- a custom user named 'admin.local'  
- the primary device user (in case of Autopilot profiles with admin enrollment)  
- the tenant's role 'Global Administrator' (SID)  
- the tenant's role 'Azure AD Joined Device Locaal Administrator' (SID)  

### check if hostname matches naming convention
  
Approved computernames are in this case (must be modified to your needs):  
- computername following the convention to start with "WIN-"  
- computername is one of "KIRK", "SPOCK" or "MCCOY"  

### check if organisation's CA certificate is present

### check if Credential Guard is enabled

### check if LAPS policy processing is successfull

### check for free disk space
  
The detection calculates the free disk space. The rules file specifies which minimun disk space is required.  