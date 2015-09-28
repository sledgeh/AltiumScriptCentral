{

}


Type
	Coordinate_t = class(Coordiante)
    function toPolar();
  private
  	x : Integer;
    x_mm : Double;
    y : Integer;
    y_mm: Double;
    r : Double;
    f : Double; // in rads
  end;
