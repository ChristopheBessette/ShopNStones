class DragTrigger extends h2d.Object{

    public function new(id:resources.ResourceId, cb:Void->Void, ?parent:h2d.Object){
        super(parent);
        var resource = new h2d.Bitmap(Assets.getResource(resources.ResourceId.Amethyst));
        resource.setScale(Const.SCALE);
        var bg_x_offset = 10;
        var bg_y_offset = 5;
        var bg = new h2d.Graphics(this);
        // bg.beginFill(0x222222, 1);
        // bg.drawRoundedRect(0, 0, 200, resource.getSize().height+bg_y_offset*2, 25, 50);
        bg.beginFill(0xffffff, 1);
        bg.drawRoundedRect(20, 5, 160, resource.getSize().height, 25, 50);
        bg.beginFill(0xbbbbbb, 1);
        bg.drawRoundedRect(50, resource.getSize().height*0.5, 100, 10, 5, 25);
        bg.endFill();
        bg.addChild(resource);
        resource.x += 60;
        resource.y += 8 * Const.SCALE + 5;
    }
}