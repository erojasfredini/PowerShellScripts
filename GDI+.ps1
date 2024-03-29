[reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
[reflection.assembly]::LoadWithPartialName("System.Drawing")

$myBrush = new-object Drawing.SolidBrush green
$myPen = new-object Drawing.Pen black

$form = new-object Windows.Forms.Form

$formGraphics = $form.CreateGraphics()

 
function DrawHandler
{
    $formGraphics.DrawLine($myPen,10,10,190,190)
    $formGraphics.FillEllipse($myBrush,20,20,180,180)
    $p1 = new-object Drawing.Point 10, 100
    $p2 = new-object Drawing.Point 100, 10
    $p3 = new-object Drawing.Point 170, 170
    $p4 = new-object Drawing.Point 200, 100

    $myPen.color = "red"
    $myPen.width = 10
    $formGraphics.DrawBezier($myPen, $p1, $p2, $p3, $p4)
}

$form.add_paint(
{
DrawHandler
}
)


$form.ShowDialog()
