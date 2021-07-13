Add-Type -AssemblyName PresentationCore,PresentationFramework



# where is the XAML file?
$xamlFile = "I:\Repo\Transfer_GUI\Transfer_Window.xaml"

#create window
$inputXML = Get-Content $xamlFile -Raw
$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[XML]$XAML = $inputXML

#Read XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load( $reader )
} catch {
    Write-Warning $_.Exception
    throw
}

# Create variables based on form control names.
# Variable will be named as 'var_<control name>'

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    #"trying item $($_.Name)"
    try {
        Set-Variable -Name "var_$($_.Name)" -Value $window.FindName($_.Name) -ErrorAction Stop
    } catch {
        throw
    }
}
Get-Variable var_*
$TransferUser = $Null
$ComparisonUser = $Null
$SelInProgress = $false

 


$var_Button_Get_Selection.add_click({

    #if($var_txt_JC.text -like "" ){
   #     Show_Warning("User and DC/JC Values Cannot Be Null")
    #}

   # else{
    #$DC = $var_txt_DC.Text
    #$JC = $var_txt_JC.Text

    $Selection = (get-aduser -filter "department -like '$($dc)*' -AND title -like '$($jc)*' -and Enabled -eq 'true'" -properties * | Select Samaccountname, DisplayName, Enabled, Department, title, DistinguishedName | Sort-Object Samaccountname |  Out-GridView -PassThru).Samaccountname
    #$Selection = (get-aduser -filter "department -like '202240*' -AND title -like '60522*' -and Enabled -eq 'true'" -properties * | Select Samaccountname, DisplayName, Enabled, Department, title, DistinguishedName | Sort-Object Samaccountname |  Out-GridView -PassThru).Samaccountname
    
    
    if(!($SelInProgress)){
    Get_Selection($Selection)
    }
    
    
})



$var_btn_Remove_Left.add_click({
    $FocusGroup = $var_ListBox_User1_Current.SelectedItem
    if(!($FocusGroup -eq $Null)){
        if(!($var_ListBox_Remove.items.Contains($FocusGroup))){
            $var_ListBox_Remove.items.add($FocusGroup)
            $var_ListBox_User1_Current.items.remove($FocusGroup)
        }
    
    }
   
})


$var_btn_Remove_Right.add_click({
    $FocusGroup = $var_ListBox_Remove.SelectedItem

    if(!($FocusGroup -eq $Null)){
        if(!($var_ListBox_User1_Current.items.Contains($FocusGroup))){
            $var_ListBox_User1_Current.items.Add($FocusGroup)
            $var_ListBox_Remove.items.Remove($FocusGroup)
            
        }
    }

    
   

})

$var_btn_addGroup.add_Click({
    $FocusGroup = $var_ListBox_User2_Current.SelectedItem

    if(!($FocusGroup -eq $Null)){
    if (!($var_ListBox_User1_Current.items.Contains($FocusGroup))){
    $var_ListBox_User1_Current.items.add($FocusGroup)
    $var_ListBox_User2_Current.items.Remove($FocusGroup)
    }}

    



})


$var_btn_RemoveGroup.add_click({
    $FocusGroup = $var_ListBox_User1_Current.SelectedItem

    if(!($FocusGroup -eq $Null)){
        if (!($Var_ListBox_User2_Current.Items.Contains($FocusGroup))) {

            $var_ListBox_User2_Current.items.Add($FocusGroup)
            $var_ListBox_User1_Current.items.Remove($FocusGroup)
        }
 
    }

})

$var_BTN_Update.add_click({
   
    $User = Get-ADUser -Identity $var_txt_User1.Text -Properties *



    $updatedGroupsList = $var_ListBox_User1_Current.items
    $GroupstoRemove = $var_ListBox_Remove.items
    
    


    $OldOU =  $var_Text_User1OU.Text
    $NewOU =  $var_Text_User2OU.Text
    
    if (Get-OUCheck) {
        #Set OU to new one
        Write-Out("Updating User OU")
        Write-out("Old OU: $OldOU")
        WRite-out("New OU: $NewOU")
        Try{
        Get-ADUser $User | Move-ADObject -TargetPath "$NewOU" -ErrorAction Stop
        }
        Catch{continue}
        }
    else {
        Write-out("Update OU unchecked, OU Check Complete...")
    }
   

    foreach ($Group in $GroupstoRemove) {
        if($group -ne $Null){
        Write-Out "Removing User from $Group" 
        try{       
        Remove-ADGroupMember -identity $Group -Members $user -Confirm:$false -ErrorAction Stop
        }
        catch{Continue}
        }
    }


    foreach ($Group in $updatedGroupsList) {
        if($group -ne $Null){
       Write-Out "Adding User to $Group"
       try{
        Add-ADGroupMember -Identity $Group -Members $User -Confirm:$false -ErrorAction Stop
       }
       Catch{continue}
        }
    }

    
    Write-Out("")
    Write-Out("User Transferred")
    Write-Out(" ")

})


Function Write-Out($Output){
    $out = "$Output `n"
    $var_Txt_Output.Text += $Out  
}

Function Get-OUCheck {
    $checked = $var_cb_UpdateOU.IsChecked
    if ($checked){
        return $true
    }
    else{return $false}
}





$Null = $window.ShowDialog()

function clear_Lists{
    #$var_ListBox_User2_Current.ItemsSource = ""
    $var_ListBox_User2_Current.Items.Clear()
    $var_ListBox_User1_Current.Items.Clear()
    $var_ListBox_Remove.items.Clear()
    
    
}


Function Get_Selection($username){
    $SelInProgress = $true
    clear_Lists
    $User1CurrentGroups = @()
    $User2CurrentGroups = @()
    $TransferUser = Get-ADUser -Identity $var_txt_User1.Text -Properties *
    $ComparisonUser = Get-ADUser -Identity $username -Properties *
    $User1CurrentGroups = Get-ADPrincipalGroupMembership $TransferUser | select Name 
    $User2CurrentGroups = Get-ADPrincipalGroupMembership $ComparisonUser | Select name 
    $User1CurrentGroups = $User1CurrentGroups |  Sort-Object -Property Name
    $User2CurrentGroups = $User2CurrentGroups | Sort-Object -Property Name
   
    $var_Label_TransfereeUser.Content = $TransferUser.name
    $var_Label_SelectedUser.Content = $ComparisonUser.Name
    
   

    

    
   
    Foreach ($Group in $User1CurrentGroups){
        $var_ListBox_User1_Current.items.Add($Group.name)
    }

    Foreach ($Group in $User2CurrentGroups){
        $var_ListBox_User2_Current.items.Add($Group.name)
        
    }

    $var_Label_TransferringUser.Content = $TransferUser.name
    $var_Label_ComparisonUser.Content = $ComparisonUser.Name

    $var_Label_CurrentOU.Content = $TransferUser.name + " OU"
    $var_Label_CorrectOU.Content = $ComparisonUser.name + " OU"

    #$var_Text_User1OU.Text = $TransferUser.CanonicalName
    $TrsfOU = ($TransferUser.DistinguishedName -split ",",2)[1]
    $var_Text_User1OU.Text = $TrsfOU

    $CompOU = ($ComparisonUser.DistinguishedName -split ",",2)[1]
    $var_Text_User2OU.Text = $CompOU

    start-sleep(2)

    $SelInProgress = $false
    
}

function Set_Status($status){


    

}

function Show_Warning($Message){    
        [System.Windows.MessageBox]::Show($Message)
}