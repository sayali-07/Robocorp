*** Settings ***
Documentation     Template robot main suite.
Library           RPA.HTTP
Library           RPA.Browser.Selenium           auto_close=${False}
Library           RPA.Word.Application
Library           RPA.Tables
Library           RPA.Cloud.AWS
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs



*** Keywords ***
Download the CSV file

    #Download   https://robotsparebinindustries.com/orders.csv 

    Add heading     Download the CSV File
    Add text input    name=url    label= Enter the URL of CSV file
    ${dialog}=    Show dialog    title=Input form
    ${result}=    Wait dialog    ${dialog}
    Download      ${result.url}
    log    ${result.url}
    #${response.Download}
    
   
Open the website and Login
   # ${Path_Credential}=  "D:\RoboCorp\Usecase_Certification2\vault.json"
    Open Available Browser    https://robotsparebinindustries.com/#/          maximized=True 
    #Click Button              OK
   # Set Selenium Speed     0.2 seconds
    ${secret}=    Get Secret    credentials
    Input Text    username    ${secret}[username]
    Input Password    password    ${secret}[password]
    Submit Form
    Click Element        //*[@id="root"]/header/div/ul/li[2]/a
    Click Button              OK
Add order details on Webpage    
    [Arguments]         ${OrderDetail}
    Select From List By Value    head                   ${OrderDetail}[Head]               #Add head value
    Select Radio Button          body                   id-body-${OrderDetail}[Body]       #Add body value
    Input Text                  //form/div[3]/input     ${OrderDetail}[Legs]               #Add legs value
    Input Text                  address                 ${OrderDetail}[Address]            #Add address 
    #Wait Until Element Is Visible        //*[@id="preview"]
    click Element                  //*[@id="preview"]                                      #Click on Preview
    #Wait Until Keyword Succeeds    3x   0.5 seconds  
    #Set Selenium Speed    1
    #Wait Until Element Is Visible        //*[@id="order"]                                  
    click Element                  //*[@id="order"]     
    Verify Order Receipt            ${OrderDetail}

Verify Order Receipt
      [Arguments]         ${OrderDetail}
    &{ExistsORNot}  Get Element Status      //*[@id="order-another"] 

        log   ${ExistsORNot.visible} 

    IF    ${ExistsORNot.visible} == True
        Log  Receipt found
        Wait Until Element Is Visible        receipt
        ${Get_HTMLReceipt}=      Get Element Attribute    receipt    outerHTML                   
        Html To Pdf         ${Get_HTMLReceipt}     ${CURDIR}${/}ReceiptPDF${/}${OrderDetail}[Order number].pdf    #Convert Receipt html to pdf
        Screenshot           robot-preview-image     ${CURDIR}${/}ReceiptPDF${/}${OrderDetail}[Order number].png  #Take robot screenshot
    
        ${files}=    Create List
        ...    ${CURDIR}${/}ReceiptPDF${/}${OrderDetail}[Order number].pdf                 #Embed the screenshot of the robot to the PDF receipt.
        ...    ${CURDIR}${/}ReceiptPDF${/}${OrderDetail}[Order number].png:x=10,y=20
    

        Add Files To PDF    ${files}      ${CURDIR}${/}Receipt_Robot${/}${OrderDetail}[Order number].pdf


        Wait And Click Button                //*[@id="order-another"]
    
        Click Button                          OK                                    #Click on Order

    ELSE

        Log  Receipt not found
        #Add order details on Webpage           ${OrderDetail} 
        click Element                  //*[@id="order"]  
        Verify Order Receipt               ${OrderDetail} 
        
    END 
   
Fill the form using the data from the CSV file
    Create Directory     ${CURDIR}${/}Receipt_Robot
    ${Ordertable}=    Read table from CSV   orders.csv
    FOR    ${OrderDetail}    IN    @{Ordertable}
     
         Add order details on Webpage            ${OrderDetail} 
        
    END
   
   
    Archive Folder With Zip          ${CURDIR}${/}Receipt_Robot    ${CURDIR}${/}Output${/}Receipt_Robot.zip  #Create Zip folder

*** Tasks ***
Template robot main suite.
    Download the CSV file
    Open the website and Login
    Fill the form using the data from the CSV file