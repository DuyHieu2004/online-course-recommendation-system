using System;
using System.Collections.Generic;

namespace online_course_recommendation_system.Models;

public partial class TienDoBaiHoc
{
    public int MaTienDoBaiHoc { get; set; }

    public int? MaBaiHoc { get; set; }

    public bool? DaHoanThanh { get; set; }

    public DateTime? LanCuoiXem { get; set; }

    public int? ThoiGian { get; set; }

    public int? MaTienDo { get; set; }

    public virtual BaiHoc? MaBaiHocNavigation { get; set; }

    public virtual TienDo? MaTienDoNavigation { get; set; }
}
