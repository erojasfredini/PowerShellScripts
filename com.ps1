function get-PlayList
{param($name)

if( $name -eq null )
    {
        $wmp.currentPlayList
    }
    else
    {
        $wmp.PlayListCollection.getByName($name)
    }

}

get-PlayList 