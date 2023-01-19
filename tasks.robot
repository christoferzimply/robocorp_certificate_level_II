*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser
Library             XML
Library             RPA.HTTP
Library             RPA.Robocorp.Vault
Library             RPA.Tables
Library             RPA.PDF
Library             Collections
Library             Dialogs
Library             RPA.Dialogs
Library             RPA.RobotLogListener
Library             RPA.FileSystem
Library             RPA.Archive


*** Tasks ***
Enter and submit robot orders
    Ask user if ready
    Download csv
    Create output directory if it does not exist
    Open the browser
    Open the order website
    Enter orders
    Zip orders directory
    Delete temp folders

#Enter order details
#    Select head


*** Keywords ***
Ask user if ready
    Add heading    Are you ready?
    Add submit buttons    buttons=No,Yes    default=Yes
    ${user_ready}    Run dialog
    Log To Console    The user is ready: ${user_ready.submit}
    IF    $user_ready.submit == 'No'    Run Keyword    Fatal Error

Create output directory if it does not exist
    ${directory_exists}    Does Directory Exist    orders
    IF    ${directory_exists} == False    Create Directory    orders

Download csv
    ${secret}    Get Secret    orders_data
    Download    ${secret}[url]    overwrite=True

Open the browser
    Open Available Browser

Open the order website
    Go To    https://robotsparebinindustries.com/#/robot-order
    ${cookie_popup_exists}    Is Element Enabled    xpath: //button[@class='btn btn-dark']
    IF    ${cookie_popup_exists} == True
        Click Button    xpath: //button[@class='btn btn-dark']
    END

Enter orders
    ${orders}    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        ${pdf_path}    Wait Until Keyword Succeeds    8x    1 sec    Enter a single order    ${order}
        Copy File    ${pdf_path}    orders/order_${order}[Order number].pdf
    END

Enter a single order
    [Arguments]    ${order}
    # Navigate to order webpage
    Open the order website
    # Select head
    Select From List By Value    id: head    ${order}[Head]
    # Select body
    Click Element    id: id-body-${order}[Body]
    # Select legs
    Input Text    xpath: //input[@placeholder='Enter the part number for the legs']    ${order}[Legs]
    # Enter address
    Input Text    id: address    ${order}[Address]
    # Click preview
    Click Element    id: preview
    # Click submit
    Click Element    id: order
    # Save pdf file
    ${pdf_path}    Save pdf    ${order}
    RETURN    ${pdf_path}

Download images
    [Arguments]    ${order}    ${folder}
#    ${head_url}    RPA.Browser.Get Element Attribute    xpath: //img[@alt='Head']    src
#    Download    ${head_url}    ${folder}/head.PNG
#    ${body_url}    RPA.Browser.Get Element Attribute    xpath: //img[@alt='Body']    src
#    Download    ${body_url}    ${folder}/body.PNG
#    ${legs_url}    RPA.Browser.Get Element Attribute    xpath: //img[@alt='Legs']    src
#    Download    ${legs_url}    ${folder}/legs.PNG
    Screenshot    xpath: //div[@id='robot-preview-image']    ${folder}/robot.png

Save pdf
    [Arguments]    ${order}
    ${pdf_folder}    Set Variable    tmp/${order}[Order number]
    ${pdf_path}    Set Variable    ${pdf_folder}/receipt_${order}[Order number].pdf
    ${receipt_attribute}    RPA.Browser.Get Element Attribute    id: receipt    outerHTML
    Html To Pdf    ${receipt_attribute}    ${pdf_path}
    Download images    ${order}    ${pdf_folder}
    ${images}    Create List
    ...    ${pdf_folder}/robot.png
#    ...    ${pdf_folder}/body.PNG
#    ...    ${pdf_folder}/legs.PNG
    Add Files To Pdf    ${images}    ${pdf_path}    append=True
    RETURN    ${pdf_path}

#    Add Files To Pdf
#    Http Get    url

Zip orders directory
    Archive Folder With Zip    orders    output/orders.zip

Delete temp folders
    Remove Directory    tmp    True
    Remove Directory    orders    True
