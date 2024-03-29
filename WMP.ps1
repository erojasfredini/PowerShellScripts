<#.WMP

    Author: Emmanuel Rojas Fredini
    Fecha ultima modificacion: 05/03/2010
    
    Objetivo: Controlar Windows Media Player desde powershell usando el objeto com.
              El player se controla mediante un par de commandos que controlan la playlist,
              media y control.

Funcionalidad:
--------------

<variable de salida de WMP> = get-WMP 

   Obtiene una instancia de WMP, todos los scrips requieren que se inicialize con esto
   y que la variable se llame wmp

get-PlayList [<nombre de la lista>]

set-PlayList <nombre de la lista o playlist>

get-MediaInPlayList <nombre de media> ["-full"]

   Con "-full" devuleve un IWMPMedia sino devuelve el nombre

get-Media [<nombre de media>] ["-album" , "-artist"]

append-Media <nombre de media o media> <nombre de playlist o playlist>

play-Media

stop-Media

pause-Media

next-Media

previous-Media

pos-Media

vol-Media
#>

#Shows the list of functions to control WindowsMediaPlayer
function global:help-WMP 
{
    echo ""
    echo "WMP Basic:"
    echo "----------"
    echo "   get-WMP              Gets an instance of WMP(the variable that catch the return need to be called $wmp)"
    echo "   get-WMPstatus        Show the status of WMP"
    echo ""
    echo "PlayList:"
    echo "---------"
    echo "   get-PlayList         If a name passed show the request playlist, if nothing pass show the current playlist plus All the playlists"
    echo "   set-PlayList         Set as current th playlist passed by the name, or if the parameter is a COM object set it directly"
    echo ""
    echo "Media:"
    echo "------"
    echo "   get-Media            If a value passed show the request media, if nothing pass show the current playlist media"
    echo "   Append-Media         Append a media to a playlist. First recibes the media and secondly the playlist"
    echo ""
    echo "Controls:"    
    echo "---------"
    echo "   play-Media           Plays current media in playlist"
    echo "   stop-Media           Stops current media"
    echo "   pause-Media          Pause current media"
    echo "   next-Media           Pass to next media in the playlist"
    echo "   previous-Media       Pass to previous media in the playlist"
    echo "   vol-Media            Set the volume of the WMP"
    echo "   pos-Media            Show the current media play position"
    echo ""
    
}

#Creates the WindowsMediaPlayer variable
#the variable need to be called $wmp
#This is the command to initialize the WMP control
#Usage: $wmp = get-WMP
function global:get-WMP 
{
    $wmp = new-object –COM WMPlayer.OCX -strict
    $wmp
}


function global:get-WMPstatus
{
    Write-Output ""
    Write-Output "Windows Media Player Status:"
    Write-Output "----------------------------"
    Write-Output ( "Current PlayList:        " + $wmp.currentPlayList.name )
    Write-Output ( "Current Media:           " + $wmp.currentMedia.name )
    Write-Output ( "Current Media position:  " + ( $wmp.Controls.currentPositionString + "/" + $wmp.currentMedia.durationString ) )
    Write-Output ( "WMP Volume:              " + $wmp.Settings.volume.ToString() )
    Write-Output ""
}

###############################
#   The PlayList cmdlets      #     
###############################

#Shows the PlayList items
#If a name is  passed - shows the playlist
#If a name not passed - show the current playlist and all the playlists
#Parameter can be passed by parameter or in the pipeline
function global:get-PlayList
{param($name)

    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }

    if( $name -eq $null )
    {
        $name=$_       #check the pipeline object
        if( $name -eq $null )#PlayList name not passed? then show current and all the playlists
        {
            echo "Current PlayList:"
            echo "-----------------"
            $wmp.currentPlayList
            echo ""
            echo "All PlayLists:"
            echo "--------------"
            $playLists = $wmp.PlayListCollection.getAll()#get and array with the playlists
            for($i=0;$i -lt $playLists.count ;$i++)
                { $playLists.item($i) }
        }
    }
    else
    {
        $list = $wmp.PlayListCollection.getByName($name)
        if( $list.count -eq 0 )#No playlist in the array then PlayList doesn't exist
        {
            echo "Error: PlayList don't exist"
        }
        else #Show PlayList
        {
            0..($list.count-1) | foreach { $list.Item($_) }#should be only 1 playlist
            return $list
        }
    }

}

#Sets the PlayList of WMP
#If a playlist by string - checks that playlist by name
#If a playlist by object - if a COM objects tries to set it
#Parameter can be passed by parameter or in the pipeline
function global:set-PlayList
{param($playlist)
    
    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }
    
    if( $playlist -eq $null )#PlayList name not passed as parameter?
        {$playlist=$_}       #then take the pipeline object       
        
    if($playlist -is [string])#playlist pass by name
    {
        if( $wmp.PlayListCollection.getByName($playlist).count -gt 0 )
        { 
            $wmp.currentPlayList = $wmp.PlayListCollection.getByName($playlist).item(0) 
            $wmp.Controls.Stop()#if playing stop... if not it is annoying
        }#Get the playlist object
        else
           { "Error: PlayList don't exist" }
    }else
    {    
        if($playlist -is [system.__ComObject])#playlist pass by object
        {
            $wmp.currentPlayList = $playlist
            $wmp.Controls.Stop()#if playing stop... if not it is annoying
        }
        else
        {
            "Error: Playlist should be the name of it or the COM object"
        }
    }
    
}


############################
#   The Media cmdlets      #     
############################

#Intended as auxiliarie function
#Shows the media in a playlist
#Parameter 1:
#  If passed a string     - uses the playlist with that name
#  If passed a COM object - uses that object as playlist
#  If nothing passed then show the current playlist
#Parameter 2:
#  If passed -full then shows the media as objects else shows the names
function global:get-MediaInPlayList
{param($playlist,[string]$detalled)

    if( $playlist -eq $null )
        {$playlist = $_}
        
    if( $playlist -is [system.__ComObject] )#if a playlist then just keep it
        { $playlist = $playlist }

    if( $playlist -eq $null )#if nothing specified then set as the current playlist
        { $playlist = $wmp.currentPlayList }
        
    if( $detalled -eq "-full")#show the detailed info or simple?
    { 
        for($i=0;$i -lt $playlist.count;$i++)
            { $wmp.currentPlayList.item($i) }
    }
    else
    { 
        for($i=0;$i -lt $playlist.count;$i++)
            { Write-Output $wmp.currentPlayList.item($i).name }
    }

}

#Show the media information in a playlist
#Parameter 1:
#  Gets the string to search, depending on the value of the opcional,
#  uses this string diferently
#Parameter opcional:
#  Case -album    by name of the album
#  Case -artist   by name of the artist
#  Else           by name of the media
#Note: if nothing passed then shows the current playlist media
function global:get-Media
{param($name,[Switch]$album,[Switch]$artist)

    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }
    
    #if nothing passed then show all the media in the current playlist
    if( $name -eq $null )
    {
        echo "Current Media:"
        echo "---------------"
        Write-Output $wmp.currentMedia.name
        echo ""
        echo "All Media in Playlist:"
        echo "-----------------------"
        get-MediaInPlayList 
    }

    #Note that mediaCollection.getBy* returns a PlayList with the media 
    #found so we use get-MediaInPlayList
    if( $artist )
        { get-MediaInPlayList $wmp.mediaCollection.getByAuthor($name) "-full"}
    elseif ( $album )
        { get-MediaInPlayList $wmp.mediaCollection.getByAlbum($name) "-full" }
    else
        { get-MediaInPlayList $wmp.mediaCollection.getByName($name) "-full"}

}

#Sets the Media of WMP
#If a media by string - checks that media by name
#If a playlist by object - if a COM objects tries to set it
#Parameter can be passed by parameter or in the pipeline
function global:set-Media
{param($media)
    
    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }
    
    if( $media -eq $null )#media name not passed as parameter?
        {$media=$_}       #then take the pipeline object       
        
    if($media -is [string])#media pass by name
    {
        if( $wmp.MediaCollection.getByName($media).count -gt 0 )
           { $wmp.currentMedia = $wmp.MediaCollection.getByName($media).item(0) }#Get the media object
        else
           { "Error: Media don't exist" }
    }else
    {    
        if($media -is [system.__ComObject])#media pass by object
        {
            $wmp.currentMedia = $media
        }
        else
        {
            "Error: Media should be the name of it or the COM object"
        }
    }
    
}

#Append a media to a playlist
#Parameter 1:
#The name or COM object of the media to append
#Parameter 2:
#The name or COM object of the playlist to append to
function Append-Media
{param($item,$playlist)

    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }

    if( $item -eq $null )
        { $item = $_ }
      
    if( $item -is [string] )
        { $item = get-Media $item }#get the media
    if( $item -is [string] )
        { "Error: The Media don't exist" }
    else
    {
        if( $playlist -eq $null )
            { $playlist = $wmp.currentPlayList }
            
        if( $playlist -is [string] )
            { $playlist = get-PlayList $playlist }#get the play list

        if( $playlist -is [string] )
            { "Error: The PlayList don't exist" }
        else
            { $playlist.appendItem($item) #append the media to the playlist
              $item = $null 
            }
    }

}


####################################
#   The Media Control cmdlets      #     
####################################

#Set WindowsMediaPlayer in Play state
function global:play-Media
{
    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }
    
    if( -not $wmp.Controls.isAvailable("play") )#I don't know why sometimes enters a state
        { $wmp.Controls.Stop(); }              #that needs to be stop to be play... but is not playing
    $wmp.controls.Play()
}

#Set WindowsMediaPlayer in Stop state
function global:stop-Media
{
    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }
    
    $wmp.controls.Stop()
}

#Set WindowsMediaPlayer in Pause state
function global:pause-Media
{
    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }

    $wmp.controls.Pause()
}

#Pass WindowsMediaPlayer to the next Media in the PlayList
function global:next-Media
{
    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }
    
    $wmp.controls.Next()
}

#Pass WindowsMediaPlayer to the previous Media in the PlayList
function global:previous-Media
{
    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }

    $wmp.controls.Previous()
}

function global:vol-Media
{param($vol)
    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }
    
    $wmp.Settings.volume = $vol
}


function global:pos-Media
{param($vol)
    if( $wmp -eq $null )#Not initialize the WMP?
    {
        echo "Error: The WMP variable isn't created"
        echo "       First use get-WMP to create $wmp variable"
        return
    }
    if( -not( $wmp -is [system.__ComObject] ) )#WMP variable not changed
    {
        echo "Error: The WMP variable isn't a WMP COM object"
        echo "       First use get-WMP to create $wmp variable properly"
        return    
    }
    
    Write-Output ( $wmp.Controls.currentPositionString + "/" + $wmp.currentMedia.durationString )
}

#get-PlayList
#"Iron Maiden" | get-PlayList

#get-MediaInPlayList
#get-Media "Iron Maiden"
#get-Media "run to the hills"

#pos-media

#get-WMP
#set-playlist "Iron Maiden"
#set-media "run to the hills"
#play-Media