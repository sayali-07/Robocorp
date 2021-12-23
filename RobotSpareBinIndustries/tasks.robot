*** Settings ***
Documentation     Download the Order file (.csv).
...               save each order HTML receipt as a PDF file.
...               save a screenshot of each of the ordered robots.
...               embed the screenshot of the robot to the PDF receipt.
...               create a ZIP archive of the PDF receipts. Store the archive in the output directory.

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

    Add heading     Download the CSV File
    Add text input    name=url    label= Enter the URL of CSV file
    ${dialog}=    Show dialog    title=Input form
    ${result}=    Wait dialog    ${dialog}
    Download      ${result.url}
    log    ${result.url}
  
    
   
Open the website and Login
  
    Open Available Browser    https://robotsparebinindustries.com/#/          maximized=True 
   
    ${secret}=    Get Secret    credentials
    Input Text    username    ${secret}[username]                             # Adding username
    Input Password    password    ${secret}[password]                         # Adding Password
    Submit Form
    
    Click Element        //*[@id="root"]/header/div/ul/li[2]/a                # Clicking on Order your robot
    Click Button              OK                                              # Clicking on ok

Add order details on Webpage    
    [Arguments]         ${OrderDetail}

    Select From List By Value    head                   ${OrderDetail}[Head]               #Adding head value
    Select Radio Button          body                   id-body-${OrderDetail}[Body]       #Adding body value
    Input Text                  //form/div[3]/input     ${OrderDetail}[Legs]               #Adding legs value
    Input Text                  address                 ${OrderDetail}[Address]            #Adding address 
    
    click Element                  //*[@id="preview"]                                      #Clicking on Preview                       
    click Element                  //*[@id="order"] 

    Verify Order Receipt            ${OrderDetail}

Verify Order Receipt
      [Arguments]         ${OrderDetail}

    &{ExistsORNot}  Get Element Status      //*[@id="order-another"] 

          log   ${ExistsORNot.visible} 

    IF    ${ExistsORNot.visible} == True                           #Checking the 'order another robot' button exists or not

        Log  Receipt found
        Wait Until Element Is Visible        receipt
        ${Get_HTMLReceipt}=      Get Element Attribute    receipt    outerHTML                   
        Html To Pdf         ${Get_HTMLReceipt}     ${CURDIR}${/}ReceiptPDF${/}${OrderDetail}[Order number].pdf    #Converting Receipt html to pdf
         
        Screenshot           robot-preview-image     ${CURDIR}${/}${/}ReceiptPDF${/}${OrderDetail}[Order number].png       #Taking robot screenshot
    
        ${files}=    Create List
        ...    ${CURDIR}${/}ReceiptPDF${/}${OrderDetail}[Order number].pdf                 #Embed the screenshot of the robot to the PDF receipt.
        ...    ${CURDIR}${/}ReceiptPDF${/}${OrderDetail}[Order number].png:x=10,y=10
    

        Add Files To PDF    ${files}      ${CURDIR}${/}Receipt_Robot${/}${OrderDetail}[Order number].pdf


        Wait And Click Button                //*[@id="order-another"]
    
        Click Button                          OK                                    #Clicking on Order

    ELSE

        Log  Receipt not found
        
        click Element                  //*[@id="order"]  
        Verify Order Receipt               ${OrderDetail} 
        
    END 
   
Fill the form using the data from the CSV file

    Create Directory     ${CURDIR}${/}Receipt_Robot

    ${Ordertable}=    Read table from CSV   orders.csv
    FOR    ${OrderDetail}    IN    @{Ordertable}
     
         Add order details on Webpage            ${OrderDetail} 
        
    END
   
    Create Directory     ${CURDIR}${/}Output
    Archive Folder With Zip          ${CURDIR}${/}Receipt_Robot    ${CURDIR}${/}Output${/}Receipt_Robot.zip  #Creating Zip folder

Close the Browser

     Close Browser    

*** Tasks ***
Template robot main suite.

    Download the CSV file
    Open the website and Login
    Fill the form using the data from the CSV file
    Close the Browser