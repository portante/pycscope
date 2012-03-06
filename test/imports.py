import abcd
import abcd.efgh.ijkl
import abcd,efgh,ijkl
import abcd.e.f.g, efgh.i.j.k, ijkl.m.n.o
import abc as xyz
import abc.x.y.z as xyz
import abcd as xyz, efg.h as uvw, ghi.j.k.l as rst

from abc import xyz
from abcd.ef.ghi import xyz
from abc import xyz, uvw, rst
from abcd.ef.ghi import xyz, uvw, rst

from abc import xyz as uvw
from abcd.ef.ghi import xyz as uvw
from abc import xyz as zyx, uvw as wvu, rst as tsr
from abcd.ef.ghi import xyz, uvw, rst
from abcd.ef.ghi import xyz, uvw, rst as tsr

from abc import *
from abcd.ef.ghi import *

from .abc import xyz
from ..abc import xyz
from ...abc import xyz
