/*************************************************************************
*									 *
*	 YAP Prolog 							 *
*									 *
*	Yap Prolog was developed at NCCUP - Universidade do Porto	 *
*									 *
* Copyright L.Damas, V.S.Costa and Universidade do Porto 1985-2006	 *
*									 *
**************************************************************************
*									 *
* File:		matrix.yap						 *
* Last rev:								 *
* mods:									 *
* comments:	Have some fun with blobs				 *
*									 *
*************************************************************************/
/**
 * @file   matrix.yap
 * @author VITOR SANTOS COSTA <vsc@VITORs-MBP.lan>
 * @date   Tue Nov 17 22:53:40 2015
 *
 * @brief  Vector, Array and Matrix  library
 *
 *
*/


:- module( matrix,
	   [(<==)/2, op(800, xfx, <==),
	    (+==)/2, op(800, xfx, +==),
	    (-==)/2, op(800, xfx, -==),
	   op(950,fy,:=),
	   op(950,yfx,:=),
%	   op(950,fx,<-),
%	   op(950,yfx,<-),
	    op(700, xfx, in),
	    op(700, xfx, within),
	    op(700, xfx, ins),
        op(450, xfx, '..'), % should bind more tightly than \/
	op(790, fx, matrix),
	op(790, fx, array),
	op(780, xfx, of),

is_matrix/1,
	matrix_new/2,
	matrix_new/3,
	matrix_new_set/4,
	    matrix_dims/2,
	    matrix_ndims/2,
	    matrix_size/2,
	    matrix_type/2,
	    matrix_to_list/2,
	    matrix_to_lists/2,
	    matrix_get/3,
	    matrix_set/3,
	    matrix_inc/2,
	    matrix_add_to_element/3,
	    matrix_dec/2,
	    matrix_inc/3,
	    matrix_dec/3,
	    matrix_arg_to_offset/3,
	    matrix_offset_to_arg/3,
	    matrix_max/2,
	    matrix_maxarg/2,
	    matrix_min/2,
	    matrix_minarg/2,
	    matrix_sum/2,
	    matrix_sum_out/3,
	    matrix_sum_out_several/3,
	    matrix_sum_logs_out/3,
	    matrix_sum_logs_out_several/3,
	    matrix_add_to_all/2,
	    matrix_agg_lines/3,
	    matrix_agg_cols/3,
	    matrix_to_logs/1,
	    matrix_to_exps/1,
	    matrix_to_exps2/1,
	    matrix_to_logs/2,
	    matrix_to_exps/2,
	    matrix_op/4,
	map_matrix/2,
		map_matrix/3,
	foldl_matrix/4,
	    matrix_op_to_all/4,
	    matrix_op_to_lines/4,
	    matrix_op_to_cols/4,
	    matrix_shuffle/3,
	    matrix_transpose/2,
	    matrix_set_all_that_disagree/5,
	    matrix_expand/3,
	    matrix_select/4,
	    matrix_column/3,
	    foreach/2,
	    foreach/4,
	    op(50, yf, []),
            op(50, yf, '()'),
            op(100, xfy, '.'),
            op(100, fy, '.')
	    ]).
:- load_foreign_files([],['YAPMatrix'], init_matrix).

:- multifile rhs_opaque/1, array_extension/2.

/**
  
 @defgroup YAPMatrix YAP Matrix Library
@ingroup YAPLibrary
@{

This package provides a fast implementation of multi-dimensional
matwrices of integers and floats. In contrast to dynamic arrays, these
matrices are multi-dimensional and compact. In contrast to static
arrays. these arrays are allocated in the stack, and disppear in
backtracking. Matrices are available by loading the library
`library(matrix)`. They are multimensional objects of type:

  + <tt>terms</tt>: Prolog terms

+ <tt>ints</tt>: bounded integers, represented as an opaque term. The
maximum integer depends on hardware, but should be obtained from the
natural size of the machine.

+ <tt>floats</tt>: floating-point numbers, represented as an opaque term.


>The matrix library also supports a B-Prolog/ECliPSe inspired `foreach`iterator to iterate over
elements of a matrix:

+ Copy a vector, element by element.

```
 foreach(I in 0..N1, X[I] <== Y[I])
```

+ The lower-triangular matrix  _Z_ is the difference between the
lower-triangular and upper-triangular parts of  _X_.

```
 foreach([I in 0..N1, J in I..N1], Z[I,J] <== X[I,J] - X[I,J])
```

+ Add all elements of a matrix by using  _Sum_ as an accumulator.

```
 foreach([I in 0..N1, J in 0..N1], plus(X[I,J]), 0, Sum)
```

    Notice that the library does not support all known matrix operations. Please
contact the YAP maintainers if you require extra functionality.

*/


/** @pred matrix_column(+ _Matrix_,+ _Column_,- _NewMatrix)_



Select from  _Matrix_ the column matching  _Column_ as new matrix  _NewMatrix_.  _Column_ must have one less dimension than the original matrix.



 */

/** @pred matrix_new_matrix(+ _Type_,+ _Dims_,+ _List_,- _Matrix_)


Create a new matrix  _Matrix_ of type  _Type_, which may be one of
`ints` or `floats`, with dimensions  _Dims_, and
initialized from list  _List_.


*/
matrix_new_matrix(ints,Dims,Source,O) :-
    flatten(Source,L),
    new_ints_matrix(Dims,L,O).
matrix_new_matrix(floats,Dims,Source,O) :-
    flatten(Source,L),
    new_floats_matrix(Dims,L,O).



/** @pred matrix_new_matrix(+ _Type_,+ _Dims_,- _Matrix_)



Create a new matrix  _Matrix_ of type  _Type_, which may be one of
`ints` or `floats`, and with a list of dimensions  _Dims_.
The matrix will be initialized to zeros.

```
?- matrix_new_matrix(ints,[2,3],Matrix).

Matrix = {..}
```
Notice that currently YAP will always write a matrix of numbers as `{..}`.


*/
matrix_new_matrix(ints,Dims,O) :-
    new_ints_matrix(Dims,O).
matrix_new_matrix(floats,Dims,O) :-
    new_floats_matrix(Dims,O).
/** @pred matrix_new_set(? _Dims_,+ _OldMatrix_,+ _Value_,- _NewMatrix_)



Create a new matrix  _NewMatrix_ of type  _Type_, with dimensions
 _Dims_. The elements of  _NewMatrix_ are set to  _Value_.


*/
matrix_new_set(ints,Dims,C,O) :-
    new_ints_matrix_set(Dims,C,O).
matrix_new_set(floats,Dims,C,O) :-
    new_floats_matrix_set(Dims,C,O).
/** @pred matrix_offset_to_arg(+ _Matrix_,- _Offset_,+ _Position_)



Given a position  _Position _ for matrix  _Matrix_ return the
corresponding numerical  _Offset_ from the beginning of the matrix.


*/
/** @pred matrix_op(+ _Matrix1_,+ _Matrix2_,+ _Op_,- _Result_)



 _Result_ is the result of applying  _Op_ to matrix  _Matrix1_
and  _Matrix2_. Currently, only addition (`+`) is supported.


*/
/** @pred matrix_select(+ _Matrix_,+ _Dimension_,+ _Index_,- _New_)



Select from  _Matrix_ the elements who have  _Index_ at
 _Dimension_.


*/
/** @pred matrix_shuffle(XF+ _Matrix_,+ _NewOrder_,- _Shuffle_)



Shuffle the dimensions of matrix  _Matrix_ according to
 _NewOrder_. The list  _NewOrder_ must have all the dimensions of
 _Matrix_, starting from 0.


*/



:- multifile rhs_opaque/1, array_extension/2.

:- meta_predicate foreach(+,0), foreach(+,2, +, -).

:- meta_predicate map_matrix(2,+).
:- meta_predicate map_matrix(3,++).
:- meta_predicate foldl_matrix(4,?,?,?).

:- use_module(library(maplist)).
:- use_module(library(mapargs)).

:- use_module(library(lists)).
:- use_module(library(ordsets)).

%term_expansion((M[I] := P), [(eval(M.[I],V) :- is_matrix(M), matrix:matrix_get(M,[I],V))]) :-
%    !.
%
%term_expansion((M.Op() := P), (eval(M.Op(),V) :- is_matrix(M), matrix:op(M,Op,V))] :-
%
%		   abstract_mat(M) :- is_matrix(M), !.

%% @pred LHS ==> RHS
%%
%% Matrix operation
%%
%% 1 Initialization:
%%
%%    - matrix(Dims,Opts) where Dims and Opts are lists:
%%
%%    - matrix(Dims), same as  matrix(Dims, [])
%%
%%    - ListOfLists,
%%
%%    - matrix(Dims) of Type
%%
%%    - matrix(Dims) of Number
%%
%%    - matrix(Dims) of Goal
%%
%%    - matrix(Dims) of Offset^Goal
%%
%%    - matrix(Dims) of call(Goal)
%%
%%    - vector(Dim,Opts) same as matrix([Dims], [])
%%
%%    - zeros(Dims), same as matrix(Dims, [])
%%
%%    - matrix[Dims], same as  matrix(Dims, [])
%%
%%    - matrix[Dims] of Def, same as  matrix(Dims) of Def
%%
%%    Dimensions may be given as:
%%    - ListOfNumbers
%%    - ListOfIntervals
%%
%%    Options are:
%%
%%    -Liveness may be one local (b), global (nb), or foreign (f).
%%    defaults:
%%              local is LHS is unbound
%%              foreign if is bound to an atom
%%
%%    - One can use use old array routines (check static_array/3) for
%%      offline arrays/
%%
%%    1. `Atom <== [1000,1001,1002]`
%%    1. `Atom <== matrix[1000] of int`
%%    2. `Atom <== matrix[333] of 0`
%%
%% The local matrices allocate on stack: 
%%    1. `Var <== [[1000],[1001],[1002]]`
%%    1. `Var <== matrix[1000] of term`
%%    2. `Var <==  matrix[333,2] of 3.1415`
%%
%%  YAP also supports foreign matrices.

/** @pred ?_LHS_ <==  ?_RHS_ is semidet


General matrix assignment operation. It evaluates the right-hand side
 according to the
left-hand side and to the matrix:

+ if  _LHS_ is part of an integer or floating-point matrix,
perform non-backtrackable assignment.
+ other unify left-hand side and right-hand size.

Matrix elements can be accessed through the `matrix_get/2` predicate
or through an <tt>R</tt>-inspired access notation (that uses the ciao
style extension to `[]`). Examples include:


  + Access the second row, third column of matrix <tt>X</tt>. Indices start from
`0`,
```
 _E_ <==  _X_[2,3]
```

+ Access all the second row, the output is a list ofe elements.
```
 _L_ <==  _X_[2,_]
```

+ Access all the second, thrd and fourth rows, the output is a list of elements.
```
 _L_ <==  _X_[2..4,_]
```

+ Access all the fifth, sixth and eight rows, the output is a list of elements.
```
 _L_ <==  _X_[2..4+3,_]
```

The right-hand side supports the following operators:

+ `[]/2`

    written as  _M_[ _Offset_]: obtain an element or list of elements
of matrix  _M_ at offset  _Offset_.

+ `../2`

    _I_.. _J_ generates a list with all integers from  _I_ to
 _J_, included.

+ `+/2`

    add two numbers, add two matrices element-by-element, or add a number to
all elements of a matrix or list.

+ `-/2 `

    subtract two numbers, subtract two matrices or lists element-by-element, or subtract a number from
all elements of a matrix or list

+ `* /2`

    multiply two numbers, multiply two matrices or lists
    element-by-element, or multiply a number from all elements of a
    matrix or list

 + `log/1`

    natural logarithm of a number, matrix or list

+ `exp/1 `

    natural exponentiation of a number, matrix or list


+ _X_ <== array[ _Dim1_,..., _Dimn_] of  _Objects_
    The of/2 operator can be used to create a new array of
 _Objects_. The objects supported are:

  + `Unbound Variable`
    create an array of free variables
  + `ints`
    create an array of integers
  + `floats`
    create an array of floating-point numbers
  + `_I_: _J_`
    create an array with integers from  _I_ to  _J_
  + `[..]`
    create an array from the values in a list

The dimensions can be given as an integer, and the matrix will be
indexed `C`-style from  `0..( _Max_-1)`, or can be given
as  an interval ` _Base_.. _Limit_`. In the latter case,
matrices of integers and of floating-point numbers should have the same
 _Base_ on every dimension.

*/


%%
%% @pred <==(Inp, Out)
%%
%% Dispatcher, with a special cases for matrices as the RH
%% may depend on the LHS.
%%
O <== V :-
    var(V),
    !,
    throw(error(instantiation_error,O<==V)).
N <== M :-
    number(M),
    !,
    set__(N,M).
N <== Lists :-
    is_list(Lists),
    !,
    subl(Lists,Dims),
    matrix_new(Dims,N,[data(Lists)]).
(N <== M) :-
    is_matrix(M),
    !,
    matrix_new(M,N,[]).
(N <== [M|Ms]) :-
    is_list(Ms),
    !,
    matrix_new([M|Ms],N,[]).
( N<== (matrix[M|Ms] of Whatever)) :-
    !,    
    N<== matrix([M|Ms]) of Whatever.
(N <== matrix(M)) :-
    !,
    matrix_new(M,N,[]).
(N<== matrix(M) of type(Type)) :-
    memberchk(Type,[ints,floats,terms]),
    !,
    matrix_new(M, N, [type(Type)]).
(N<== matrix(M) of Op) :-
	!,
    matrix_new(M, N, [fill(Op)]).
(N <== zeros(M)) :-
    number(M),
    !,
    matrix_new([M],N,[]).
(N <== zeros(M)) :-
	!,
    matrix_new(M,N,[]).
N<== ones(M) :-
	!,
    matrix_new(M, N, [fill(1)]).
%N <==range(M) :- 
 %   matrix_new(range(M),N,[]), !.
	
LHS <== RHS :-
    compute(RHS, Val),
    set__(LHS,Val).

( LHS[Off|Offs] +== 1 ) :-
    maplist(compute,[Off|Offs],[EOff|EOffs]), 
    compute(LHS,M),
    matrix_inc(M,[EOff|EOffs]),
    !.
( LHS[Off|Offs] +== RHS ) :-
    maplist(compute,[Off|Offs],[EOff|EOffs]), 
    compute(RHS,V),
    compute(LHS,M),
    !,
    matrix_add_to_element(M,[EOff|EOffs],V).
( LHS[Off|Offs] -== 1 ) :-
    !,
    maplist(compute,[Off|Offs],[EOff|EOffs]), 
    compute(LHS,M),
    matrix_dec(M,[EOff|EOffs]).

(LHS  -== RHS ) :-
    compute(RHS,V),
    !,
    matrix_op(LHS,V,1,LHS).

/**
  @pred  map_matrix(Pred, A)

  Apply Pred(A,Index) to every element of matrix _A_, where _Index_ ranges over all entries in the array.

  As an example, to transform a floating point matrix into a logs matrix:

```{.prolog}
log(A,[X,Y]) :- V <== A[X,Y], LV is log(V), A[X,Y] <== LV.

?- X <== [[1.2,0.9,5],[0.1.0.2,0.3]], map_matrix(log, X),  Y <== X.list().
```
*/
map_matrix(Pred,A) :-
matrix_size(Pred,Size),
 do_map(Pred, A, 0, Size).

do_map(_P, _A, I, I) :- !.
do_map(P, A, I, Size) :-
    matrix_offset_to_arg(A, I, Index),
    call(P,A,Index),
    I1 is I+1,
    do_map(P, A, I1, Size).


map_matrix(Pred,A, B) :-
matrix_size(A,Size),
 do_map(Pred, A, B, 0, Size).

do_map(_P, _A,_B, I, I) :- !.
do_map(P, A, B,I, Size) :-
    matrix_offset_to_arg(A, I, Index),
    call(P,A,B,Index),
    I1 is I+1,
    do_map(P, A, B, I1, Size).


/**
  @pred  foldl_matrix(Pred, A, V0, VF)

  Apply Pred(A,Index,V1,V2) to every element of matrix _A_, where _Index_ ranges over all entries in the array.

  As an example, to sum all elements of a numeric matrix:
```{.prolog}
add(A,	I, S0, S) :- matrix_get( A, I, V), S is S0+V.

sum_matrix(A,S) :- foldl_matrix(add,A,0,S).

?- X <== [[1.2,0.9,5],[0.1,0.2,0.3]], sum_matrix(X,S).
```
*/

foldl_matrix(Pred,A,V0,VF) :-
matrix_size(A,Size),
 do_foldl(0, Size, Pred, A, V0, VF).

do_foldl(I, I, _P, _A, V, V) :- !.
do_foldl(I0, Size, P, A, V0, VF) :-
    matrix_offset_to_arg(A, I0, Index),
    call(P,A,Index, V0, VI),
    I1 is I0+1,
    do_foldl( I1, Size, P, A, VI, VF).

/** @pred compute(Inp,Out)
 *
 * Compute the value of Inp and binds the free variable Out to
 * it
*/
compute(N, M) :-
    var(N),
    !,
    M=N.
compute(N, M) :-
    number(N),
    !,
    M=N.

compute(M, M) :-
    is_matrix(M),
    !.
compute(N, M) :-
    is_list(N),
    !,
    N1 <== N,
    compute(N1,M).

/**> `V <== M[Is]`: fetch a value _V_ from array _M_ and index _Is_.

     Notice that this routine evaluates and the indices. That is:
     
```
A <== [[1,2],[3,4]], B = [[1,-2],[-3,4]], V <== (A+B)[0, 0].
```

The result is `V=2`. YAP converts _B_ to a matrix, adds the matrix _A_ and the _B_ matrix, and finally extracts the first element.
*/
compute('[]'(Is,M),V) :-
    compute(M, MV),
    maplist(compute,Is,	IVs),
   !,
    matrix_get(MV,IVs,V).


compute(Matrix.dims(), V) :-
    compute(Matrix,MatrixV),
    !,
    matrix_dims(MatrixV, V).  /**>  list with matrix dimensions */

compute(Matrix.type(), V) :-
    compute(Matrix,MatrixV),
    !,
    matrix_type(MatrixV, V).  /**>  list with matrix dimensions */

compute(Matrix.ndims(), V) :-
    compute(Matrix,MatrixV),
    !,
    matrix_ndims(MatrixV, V).  /**>  list with matrix dimensions */

compute(Matrix.sum(), V) :-
    !,
    compute(Matrix,MatrixV),
    matrix_sum(MatrixV, V).  /**>  lisT with matrix dimensions */

compute(Matrix.nrows(), V) :-
    !,
    compute(Matrix,MatrixV),
    matrix_dims(MatrixV, [V,_]).  /**>  number of rows in bi-dimensional matrix */

compute(Matrix.ncols(), V) :-
    !,
    compute(Matrix,MatrixV),
    matrix_dims(MatrixV, [_,V]).  /**>  number of columns in bi-dimensional matrix */

compute(Matrix.length(), V) :- !,
    compute(Matrix,MatrixV),
    matrix_size(MatrixV, V).  /**>  size of a matrix*/

compute(Matrix.size(), V) :-
    !,
    compute(Matrix,MatrixV),
    matrix_size(MatrixV, V).  /**>  size of a matrix*/

compute(Matrix.max(), V) :-
    !,
    compute(Matrix,MatrixV),
    matrix_max(MatrixV, V).  /**>    maximum element of a numeric matrix*/

compute(Matrix.maxarg(), V) :- !,
    compute(Matrix,MatrixV),
    matrix_maxarg(MatrixV, V).  /**    argument of maximum element of a numeric matrix*/

compute(Matrix.min(), V) :-
    !,
    compute(Matrix,MatrixV),
    matrix_min(MatrixV, V).  /**    minimum element of a numeric matrix*/

compute(Matrix.minarg(), V) :-
    !,
    compute(Matrix,MatrixV),
    matrix_minarg(MatrixV, V).  /**>    argument of minimum element of a numeric matrix*/

compute(Matrix.list(), V) :-
    !,
    compute(Matrix,MatrixV),

    matrix_to_list(MatrixV, V).  /**>    represent matrix as a list*/

compute(Matrix.lists(), V) :-
    !,
    compute(Matrix,MatrixV),
    matrix_to_lists(MatrixV, V).  /**> represent matrix as a list of lists */

compute(-B, C) :-
    compute(B, NB),
    (
	number(NB)
    ->
    C is -NB
    ;
    matrix_op_to_all(B, 2, -1, C)  /**> sq */
    ), !.

compute(A+B, C) :-
    !,
    compute(A, NA),
    compute(B, NB),
    (
	number(NA)
    ->
	(
	number(NB)
	->
	    C is NA+NB
	;
    matrix_op_to_all(NA, 0, NB, C)  /**> sq */
    )
     ;
    matrix_op(NA, NB, 0, C)  /**> sq */
    ).

compute(A-B, C) :-
    !,
    compute(A, NA),
    compute(B, NB),
    (
	number(NA)
    ->
	(
	number(NB)
	->
	    C is NA-NB
	;
    matrix_op_to_all(NA, 1, NB, C)  /**> sq */
    )
    ;
    matrix_op(NA, NB, 1, C)  /**> sq */
    ).
compute(A*B, C) :-
    !,
    compute(A, NA),
    compute(B, NB),
    (
	number(NA)
    ->
	(
	number(NB)
	->
	    C is NA*NB
	;
    matrix_op_to_all(NA, 2, NB, C)  /**> sq */
    )
    ;
    matrix_op(NA, NB, 2, C)  /**> sq */
    ).
compute(A/B, C) :-
    !,
    compute(A, NA),
    compute(B, NB),
    (
	number(NA)
    ->
    C is NA/NB
    ;
	number(NB)
    ->
    matrix_op_to_all(NA, 3, NB, C)  /**> sq */
    ;
    matrix_op(NA, NB, 3, C)  /**> sq */
    ).
compute(Cs,Exp) :-
    Cs =.. [Op,X],
  compute(X,NX),
  N=..[Op,NX],
  catch( Exp is N,_,fail),
!.


compute(Cs,Exp) :-
  Cs =.. [Op,X,Y],
  compute(X,NX),
  compute(Y,NY),
  N=..[Op,NX,NY], 
  catch( Exp is N,_,fail),
 !.




/**
+ `matrix/1`

    create a vector from a list

+ `matrix/2`

    create a matrix from a list. Options are:
  + dim=
    a list of dimensions

   + type=
    integers, floating-point or terms

  + base=
    a list of base offsets per dimension (all must be the same for arrays of
integers and floating-points

+ `matrix/3`

    create matrix giving two options

*/

matrix_new( Matrix, Target ) :-
    matrix_new( Matrix, Target, []).


liveness(Target, f) :-
    atom(Target),
    !.
liveness(_Target, b).

type(Opts, _, _, Type) :-
    memberchk(type(Type), Opts),
    !.
type(_Opts, copy, [Data|_], ints) :-
    first(Data, F),
    integer(F),
    !.
type(_Opts, copy, [Data|_], floats) :-
    first(Data, F),
    float(F),
    !.
type(_Opts, copy, _, terms) :-
    !.
type(_Opts, fill, Data, ints) :-
    integer(Data),
    !.
type(_Opts, fill, Data, floats) :-
    float(Data),
    !.
type(_Opts, fill, _, terms).


data(Opts, fill, Who) :-
    memberchk(fill(Fill), Opts),
    !,
    filler_data(Fill, Who).
data(Opts, copy, Data) :-
    memberchk(data(Data), Opts),
    !.
data(_Opts, fill, 0) :-
    !.

filler_data(Fill, Fill) :-
    number(Fill),
    !.
filler_data(floats, 0.0) :-
    !.
filler_data(ints, 0) :-
    !.
filler_data(Fill, Fill).



dimensions([H|List],[H|List],0) :-
    number(H),
    !.
dimensions([A..B|List],[H|NList],A) :-
    H is B-A,
    intervals(List, NList, A).

intervals([], [], _A).
intervals([A..B|List], [H|NList], A) :-
    H is B-A,
    intervals(List, NList, A),
    number(H),
    !.
    
subl([H|L],[N|NL]) :-
    !,
    length([H|L],N),
    subl(H,NL).
subl(_,[]).

matrix_new( Matrix, Target, _Opts ) :-
    is_matrix(Matrix),
    is_matrix(Target),
    %validate(Ops),
    !,
    matrix_copy(Matrix, Target).
matrix_new( Matrix, Target, _Opts ) :-
    is_matrix(Matrix),
    atom(Target),
    !,
    matrix_dims(Matrix,Dims),
    matrix_type(Matrix,Type),
    matrix_create(Type,
		  f,Dims,0,fill,0,Target),
    matrix_copy(Matrix, Target).
matrix_new( Matrix, Target, _Opts ) :-
    is_matrix(Matrix),
    !,
    matrix_dims(Matrix,Dims),
    matrix_type(Matrix,Type),
    matrix_new_matrix(Type,Dims,Target),
    matrix_copy(Matrix, Target).
matrix_new( Info, Target, Opts) :-
    dimensions(Info, Dims, Base),
    data(Opts, WhatWhen, Data),
    type(Opts, WhatWhen, Data, Type),
    liveness(Target, Live),
    matrix_create(Type, Live, Dims, Base, WhatWhen, Data, Target).

matrix_create(terms, b, Dims, Base, _, Data,
   '$matrix'(Dims, NDims, Size, Base, Matrix ) ) :-
    length([H|Dims],NDims),
    length(Offsets,NDims),
    maplist('='(Base),Offsets),
    Dims=[H|RDims],
    multiply(RDims,H,Size),
    flatten(Data,List),
    Matrix =.. [matrix|List],
    functor(Matrix,matrix,Size).
matrix_create(Type, b, Dims, _Base, fill, 0,New) :-
    !,
    matrix_new_matrix(Type,Dims,New).
matrix_create(Type, b, Dims, _Base, fill, C,New) :-
    !,
    matrix_new_set(Type,Dims,C,New).
matrix_create(Type, b, Dims, _Base, copy, C,New) :-
    !,
    matrix_new_matrix(Type,Dims,C,New).
matrix_create(ints, f, Dims, _Base, fill, 0,New) :-
    !,
    static_array(New,Dims,int).
matrix_create(floats, f, Dims, _Base, fill, 0,New) :-
    !,
    static_array(New,Dims,float).
matrix_create(floats, f, Dims, _Base, fill, C,New) :-
    !,
    static_array(New,Dims,float),
    update_whole_array(New,C).
matrix_create(ints, f, Dims, _Base, fill, C,New) :-
    !,
    static_array(New,Dims,int),
    update_whole_array(New,C).
matrix_create(floats, f, Dims, _Base, copy, Lists,New) :-
    !,
    static_array(New,Dims,float),
    flatten(Lists,List),
    matrix_set_all(New,List).    
matrix_create(ints, f, Dims, _Base, copy, Lists,New) :-
    !,
    static_array(New,Dims,int),
    flatten(Lists,List),
    matrix_set_all(New,List).    


zip(A-B0,A,B0,B1) :- B1 is B0+1.

multiply([],P,P).
multiply([X|Xs],P0,P) :-
    Pi is X*P0,
    multiply(Xs,Pi,P).
    

foreach( Domain, Goal) :-
	strip_module(Goal, M, Locals^NG), !,
	term_variables(Domain+Locals, LocalVarsL),
	LocalVars =.. [vs|LocalVarsL],
	iterate( Domain, [], LocalVars, M:NG, [], [] ),
	terms:reset_variables( LocalVars ).
foreach( Domain, Goal ) :-
	strip_module(Goal, M, NG),
	term_variables(Domain, LocalVarsL),
	LocalVars =.. [vs|LocalVarsL],
	iterate( Domain, [], LocalVars, M:NG, [], [] ),
	terms:reset_variables( LocalVars ).

foreach( Domain, Goal, Inp, Out) :-
	strip_module(Goal, M, Locals^NG), !,
	term_variables(Domain+Locals, LocalVarsL),
	LocalVars =.. [vs|LocalVarsL],
	iterate( Domain, [], LocalVars, M:NG, [], [], Inp, Out).
foreach( Domain, Goal, Inp, Out ) :-
	strip_module(Goal, M, NG),
	term_variables(Domain, LocalVarsL),
	LocalVars =.. [vs|LocalVarsL],
	iterate( Domain, [], LocalVars, M:NG, [], [], Inp, Out ).

iterate( [], [], LocalVars, Goal, Vs, Bs ) :-
	terms:freshen_variables(LocalVars),
	Vs = Bs,
	MG <== Goal,
	once( MG ),
	terms:reset_variables(LocalVars).
iterate( [], [H|Cont], LocalVars, Goal, Vs, Bs ) :-
	iterate(H, Cont, LocalVars, Goal, Vs, Bs ).
iterate( [H|L], [], LocalVars, Goal, Vs, Bs ) :- !,
	iterate(H, L, LocalVars, Goal, Vs, Bs ).
iterate( [H|L], Cont, LocalVars, Goal, Vs, Bs ) :- !,
	append(L, Cont, LCont),
	iterate(H, LCont, LocalVars, Goal, Vs, Bs ).
iterate( [] ins _A .. _B, [H|L], LocalVars, Goal, Vs, Bs ) :- !,
	iterate(H, L, LocalVars, Goal, Vs, Bs ).
iterate( [] ins _A .. _B, [], LocalVars, Goal, Vs, Bs ) :- !,
	iterate([], [], LocalVars, Goal, Vs, Bs ).
iterate( [V|Ps] ins A..B, Cont, LocalVars, Goal, Vs, Bs  ) :-
	eval(A, Vs, Bs, NA),
	eval(B, Vs, Bs, NB),
	( NA > NB ->  true ;
	  A1 is NA+1,
	  iterate( Ps ins NA..NB, Cont, LocalVars, Goal, [V|Vs], [NA|Bs] ),
	  iterate( [V|Ps] ins A1..NB, Cont, LocalVars, Goal, Vs, Bs )
	).
iterate( V in A..B, Cont, LocalVars, Goal, Vs, Bs) :-
	var(V),
	eval(A, Vs, Bs, NA),
	eval(B, Vs, Bs, NB),
	( NA > NB -> true ;
	  A1 is NA+1,
	  (Cont = [H|L] ->
	   iterate( H, L, LocalVars, Goal, [V|Vs], [NA|Bs] )
	  ;
	   iterate( [], [], LocalVars, Goal, [V|Vs], [NA|Bs] )
	  ),
	  iterate( V in A1..NB, Cont, LocalVars, Goal, Vs, Bs )
	).

iterate( [], [], LocalVars, Goal, Vs, Bs, Inp, Out ) :-
	terms:freshen_variables(LocalVars),
	Vs = Bs,
	MG <== Goal,
	once( call(MG, Inp, Out) ),
	terms:reset_variables(LocalVars).
iterate( [], [H|Cont], LocalVars, Goal, Vs, Bs, Inp, Out ) :-
	iterate(H, Cont, LocalVars, Goal, Vs, Bs, Inp, Out ).
iterate( [H|L], [], LocalVars, Goal, Vs, Bs, Inp, Out ) :- !,
	iterate(H, L, LocalVars, Goal, Vs, Bs, Inp, Out ).
iterate( [H|L], Cont, LocalVars, Goal, Vs, Bs, Inp, Out ) :- !,
	append(L, Cont, LCont),
	iterate(H, LCont, LocalVars, Goal, Vs, Bs, Inp, Out ).
iterate( [] ins _A .. _B, [], LocalVars, Goal, Vs, Bs, Inp, Out ) :- !,
	iterate([], [], LocalVars, Goal, Vs, Bs, Inp, Out ).
iterate( [] ins _A .. _B, [H|L], LocalVars, Goal, Vs, Bs, Inp, Out ) :- !,
	iterate(H, L, LocalVars, Goal, Vs, Bs, Inp, Out ).
iterate( [V|Ps] ins A..B, Cont, LocalVars, Goal, Vs, Bs, Inp, Out  ) :-
	eval(A, Vs, Bs, NA),
	eval(B, Vs, Bs, NB),
	( NA > NB ->  Inp = Out ;
	  A1 is NA+1,
	  iterate( Ps ins A..B, Cont, LocalVars, Goal, [V|Vs], [NA|Bs], Inp, Mid ),
	  iterate( [V|Ps] ins A1..NB, Cont, LocalVars, Goal, Vs, Bs, Mid, Out )
	).
iterate( V in A..B, Cont, LocalVars, Goal, Vs, Bs, Inp, Out) :-
    var(V),
    eval(A, Vs, Bs, NA),
    eval(B, Vs, Bs, NB),
    ( NA > NB -> Inp = Out ;
      A1 is NA+1,
      (Cont = [H|L] ->
	   iterate( H, L, LocalVars, Goal, [V|Vs], [NA|Bs], Inp, Mid )
      ;
      iterate( [], [], LocalVars, Goal, [V|Vs], [NA|Bs], Inp, Mid )
	  ),
      iterate( V in A1..NB, Cont, LocalVars, Goal, Vs, Bs, Mid, Out )
    ).


eval(I, _Vs, _Bs, I) :- integer(I), !.
eval(I, Vs, Bs, NI) :-
	copy_term(I+Vs, IA+Bs),
	NI <== IA.

matrix_seq(A, B, Dims, M) :-
	ints(A, B, L),
	matrix_new_matrix(ints, Dims, L, M).

ints(A,B,O) :-
	( A > B -> O = [] ; O = [A|L], A1 is A+1, ints(A1,B,L) ).

  /**
     case
*/
set__( VF, V) :-
    var(V),
    !,
    V=VF.
set__( VF, V) :-
    var(VF),
    !,
    V = VF.
set__(M,V) :-
    is_matrix(M),
    
    !,
    (
	number(V)
    ->
    matrix_set_all(M,V)
    ;
    is_list(V)
    ->
    foldl(set_l(M),V,0,_)
    ;
    is_matrix(V) ->
    matrix_copy(V,M)
    ).
set__('[]'(Args,M), Val) :-
    !,
    matrix_set(M,Args,Val).

matrix_set(M, Arg, Val) :-
    integer(Arg),
    !,
    matrix_set_one(M,[Arg],Val).
matrix_set(M, Args, Val) :-
    maplist(integer, Args),
    !,
    matrix_set_one(M,Args,Val).
/*
matrix_set(M, Args, Val) :-
    dims( M, Dims, Bases),
    maplist( index(Range), Args, Dims, Bases, NArgs),
    (
	var(Range)
    ->
    set_el( M, Args, Val )
    ;
    matrix_set_range( M, NArgs, Val )
    ).
*/

set_l(M,El,I,I1) :-
    M[I] <== El,
    I1 is I+1.
%c
% ranges of arguments
%
index(Range, V, M, Base, Indx) :- var(V), !,
	Max is (M-1)+Base,
	index(Range, Base..Max, M, Base, Indx).
index(Range, '*', M, Base, Indx) :- !,
	Max is (M-1)+Base,
	index(Range, Base..Max, M, Base, Indx).
index(Range, Exp, M, _Base, Indx) :- !,
	index(Exp, M, Indx0),
	( integer(Indx0) -> Indx = Indx0 ;
	  Indx0 = [Indx] -> true ;
	  Indx0 = Indx, Range = range ).

index(I, _M, I ) :- integer(I), !.
index(I..J, _M, [I|O] ) :- !,
	I1 is I, J1 is J,
	once( foldl(inc, O, I1, J1) ).
index(I:J, _M, [I|O] ) :- !,
	I1 is I, J1 is J,
	once( foldl(inc, O, I1, J1) ).
index(I+J, M, O ) :- !,
	index(I, M, I1),
	index(J, M, J1),
	add_index(I1, J1, O).
index(I-J, M, O ) :- !,
	index(I, M, I1),
	index(J, M, J1),
	sub_index(I1, J1, O).
index(I*J, M, O ) :- !,
	index(I, M, I1),
	index(J, M, J1),
	O is I1*J1.
index(I rem J, M, O ) :- !,
	index(I, M, I1),
	index(J, M, J1),
	O is I1 rem J1.
index(I, M, NI ) :-
	maplist(indx(M), I, NI).

indx(M, I, NI) :- index(I, M, NI).

add_index(I1, J1, O) :-
	integer(I1),
	integer(J1),
	O is I1+J1.
add_index(I1, J1, O) :-
	integer(I1), !,
	maplist(plus(I1), J1, O).
add_index(I1, J1, O) :-
	integer(J1), !,
	maplist(plus(J1), I1, O).
add_index(I1, J1, O) :-
	ord_union(I1, J1, O).

sub_index(I1, J1, O) :-
	integer(I1),
	integer(J1), !,
	O is I1-J1.
sub_index(I1, J1, O) :-
	integer(I1), !,
	maplist(rminus(I1), J1, O).

sub_index(I1, J1, O) :-
	integer(J1), !,
	maplist(minus(J1), I1, O).
sub_index(I1, J1, O) :-
	ord_subtract(I1, J1, O).

minus(X, Y, Z) :- Z is X-Y.

rminus(X, Y, Z) :- Z is Y-X.

times(X, Y, Z) :- Z is Y*X.

div(X, Y, Z) :- Z is X/Y.

rdiv(X, Y, Z) :- Z is Y/X.

zdiv(X, Y, Z) :- (X == 0 -> Z = 0 ; X == 0.0 -> Z = 0.0 ; Z is X / Y ).

mplus(I1, I2, V) :-
	 (is_matrix(I1) ->
	    ( number(I2) -> matrix_op_to_all(I1, +, I2, V) ;
	      is_matrix(I2) ->  matrix_op(I1, I2, +, V) ;
	      V is I1+I2 ) ;
	 is_list(I1) ->
	    ( number(I2) -> maplist(plus(I2), I1, V) ;
      is_list(I2) ->  maplist(plus, I1, I2, V) ;
	      V is I1+I2 ) ;
	    V is I1 +I2
	    ).

msub(I1, I2, V) :-
        	 (is_matrix(I1) ->
        	    ( number(I2) -> matrix_op_to_all(I1, -, I2, V) ;
        	      is_matrix(I2) ->  matrix_op(I1, I2, -, V) ;
        	      V is I1-I2 ) ;
        	 is_list(I1) ->
        	    ( number(I2) -> maplist(minus(I2), I1, V) ;
        	      is_list(I2) ->  maplist(minus, I1, I2, V) ;
        	      V is I1-I2 ) ;
        	    V is I1-I2
        	    ).



mtimes(I1, I2, V) :-
        	 (is_matrix(I1) ->
        	    ( number(I2) -> matrix_op_to_all(I1, *, I2, V) ;
        	      is_matrix(I2) ->  matrix_op(I1, I2, *, V) ;
        	      V is I1*I2 ) ;
        	 is_list(I1) ->
        	    ( number(I2) -> maplist(times(I2), I1, V) ;
        	      is_list(I2) ->  maplist(times, I1, I2, V) ;
        	      V is I1*I2 ) ;
        	    V is I1*I2
        	    ).

mfdiv(I1, I2, V) :-
        	 (is_matrix(I1) ->
        	    ( number(I2) -> matrix_op_to_all(I1, /, I2, V) ;
        	      is_matrix(I2) ->  matrix_op(I1, I2, /, V) ;
        	      V is I1/I2 ) ;
        	 is_list(I1) ->
        	    ( number(I2) -> maplist(div(I2), I1, V) ;
        	      is_list(I2) ->  maplist(div, I1, I2, V) ;
        	      V is I1/I2 ) ;
        	    V is I1/I2
        	    ).


mneg(I1, V) :-
        	 (is_matrix(I1) ->
        	    matrix_op_to_all(I1, *, -1, V) ;
        	 is_list(I1) ->
        	     maplist(mult(-1),I1, V) ;
        	    V is -I1
        	    ).

%
% three types of matrix: integers, floats and general terms.
%
mult(V,X,Y) :- Y is V*X.

matrix_to_lists( Mat, ToList) :-
	matrix_dims( Mat, [D|Dims] ),
	D1 is D-1,
	foreach( I in 0..D1, matrix_slicer( Dims, Mat, [I|L]-L), ToList, [] ).

matrix_slicer( [_], M, Pos-[_], [O|L0], L0) :- !,
	O <== '[]'(Pos,M).
matrix_slicer( [D|Dims], M, Pos-[I|L], [O|L0], L0) :-
	D1 is D-1,
	foreach( I in 0..D1 , L^matrix_slicer( Dims, M, Pos-L), O, [] ).

/** @pred matrix_get(+ _Matrix_,+ _Position_,- _Elem_)

Unify  _Elem_ with the element of  _Matrix_ at position
 _Position_, or with a list of elements i if Pod is a range.


*/
matrix_get( Mat, Pos, El) :-
    maplist(integer,Pos),

    !,
    matrix_get_one(Mat, Pos, El).
matrix_get( Mat, Pos, El) :-
    matrix_get_range( Mat, Pos, El).

matrix_get_range( Mat, Pos, Els) :-
	slice(Pos, Keys),
	maplist( matrix_get_one(Mat), Keys, Els).

slice([], [[]]).
slice([[H|T]|Extra], Els) :- !,
	slice(Extra, Els0),
	foldl(add_index_prefix( Els0 ), [H|T], Els, [] ).
slice([H|Extra], Els) :- !,
	slice(Extra, Els0),
	add_index_prefix( Els0 , H, Els, [] ).

add_index_prefix( [] , _H ) --> [].
add_index_prefix( [L|Els0] , H ) -->  [[H|L]],
	add_index_prefix( Els0 , H ).


/** @pred matrix_type(+ _Matrix_,- _Type_)



Unify  _NElems_ with the type of the elements in  _Matrix_.

u)(
*/

matrix_type(Matrix,Type) :-
    ( matrix_short_type(Matrix, T) ->
      ( T =:= "i"  -> Type = ints ; T =:= "f" -> Type = floats );
	  Type = terms ).

matrix_base(Matrix, Bases) :-
    matrix_dims(Matrix, Bases).

/** @pred matrix_agg_lines(+ _Matrix_,+Operator,+ _Aggregate_)s



If  _Matrix_ is a n-dimensional matrix, unify  _Aggregate_ with
the n-1 dimensional matrix where eaceh element is obtained by adding all
_Matrix_ elements with same last n-1 index. Currently, only addition is supported.


*/

matrix_agg_lines(M1,+,NM) :-
	do_matrix_agg_lines(M1,0,NM).
/* other operations: *, logprod */

/** @pred matrix_agg_cols(+ _Matrix_,+Operator,+ _Aggregate_)



If  _Matrix_ is a n-dimensional matrix, unify  _Aggregate_ with
the one dimensional matrix where each element is obtained by adding all
Matrix elements with same  first index. Currently, only addition is supported.


*/

matrix_agg_cols(M1,+,NM) :-
	do_matrix_agg_cols(M1,0,NM).
/* other operations: *, logprod */



/* other operations: *, logprod */


matrix_op_to_lines(M1,M2,/,NM) :-
	do_matrix_op_to_lines(M1,M2,3,NM).
/* other operations: *, logprod */

/** @pred matrix_op_to_cols(+ _Matrix1_,+ _Cols_,+ _Op_,- _Result_)



 _Result_ is the result of applying  _Op_ to all elements of
 _Matrix1_, with the corresponding element in  _Cols_ as the
second argument. Currently, only addition (`+`) is
supported. Notice that  _Cols_ will have n-1 dimensions.

*/
matrix_op_to_cols(M1,M2,+,NM) :-
	do_matrix_op_to_cols(M1,M2,0,NM).
/* other operations: *, logprod */


/** @pred matrix_transpose(+ _Matrix_,- _Transpose_)



Transpose matrix  _Matrix_ to   _Transpose_. Equivalent to:

```
matrix_transpose(Matrix,Transpose) :-
        matrix_shuffle(Matrix,[1,0],Transpose).
```


*/

matrix_transpose(M1,M2) :-
	matrix_shuffle(M1,[1,0],M2).

size(N0, N1, N2) :-
	N2 is N0*N1.

% use 1 to get access to matrix
m_get('$matrix'(Dims, _, Sz, Bases, M), Indx, V) :-
	foldl2(indx, Indx, Dims, Bases, Sz, _, 1, Offset),
	arg(Offset, M, V).


indx( I, Dim, Base, BlkSz, NBlkSz, I0, IF) :-
	NBlkSz is BlkSz div Dim ,
	IF is (I-Base)*NBlkSz + I0.

offset( I, Dim, BlkSz, NBlkSz, Base, I0, IF) :-
	NBlkSz is BlkSz div Dim,
	I is I0 div NBlkSz + Base,
	IF is I0 rem NBlkSz.

first([H|_],F) :-
    !,
    first(H,F).
first(F,F).

inc(I1, I, I1) :-
	I1 is I+1.
/**                                                                             */


% base case


/** @} */

%%% most often we can avoid meta-calls.

:- multifile user:inline/2.

user:inline(map_matrix(P,A),
    (matrix:matrix_size(A,Size), MainCall)):-
    callable(P),
    	  aux_pred(`map1`,P,
		[[0,Size,A], % plugin call
		 [I0,Size,A], % head
		 [A,Index], % inner call 
		 [I,Size,A]], % recursive call
	[MainCall, Head, Inner, Recursive]),
	  compile_clauses([(
		Head :-
	             (I0==Size -> true ;
    matrix_offset_to_arg(A, I0, Index),
		     I is I0+1,
		     Inner,
		     Recursive))] ).

user:inline(map_matrix(P,A,B),
    (matrix:matrix_size(A,Size), MainCall)):-
	  callable(P),
    	  aux_pred(`map2`,P,
		[[0,Size,A,B], % plugin call
		 [I0,Size,A,B], % head
		 [A,B,Index], % inner call 
		 [I,Size,A,B]], % recursive call
	[MainCall, Head, Inner, Recursive]),
	  compile_clauses([(
		Head :-
	             (I0==Size -> true ;
    matrix_offset_to_arg(A, I0, Index),
		     I is I0+1,
		     Inner,
		     Recursive))] ).




%%% most often we can avoid meta-calls.
user:inline(foldl_matrix(P,A,V0,VF),
    (matrix:matrix_size(A,Size), MainCall)):-
   writeln(ok), callable(P),	
    	  aux_pred(`foldl`,P,
		[[0,Size,A,V0,VF], % plugin call
		 [I0,Size,A,V0,VF], % head
		 [A,Index,V0,VF], % inner call 
		 [I,Size,A,V0,VF]], % recursive call
	[MainCall, Head, Inner, Recursive]),
	  compile_clauses([(
		Head :-
	             (I0==Size -> V0=VF ;
    matrix_offset_to_arg(A, I0, Index),
		     I is I0+1,
		     Inner,
		     Recursive))] ).

aux_pred(Op,P, [CallArgs0, HeadArgs0, InnerArgs0, RecursiveArgs0],
	       [Call, Head, Mod:Inner, Recursive]) :-
	       current_source_module(Mod,Mod),
term_to_string(Mod:P, SG),
    string_concat([Op,`_`,SG], S),
    string_atom(S,F),
    P =.. [G|Args],
    append(Args,CallArgs0,CallArgs),
    Call =.. [F|CallArgs],
    append(Args,HeadArgs0,HeadArgs),
    Head =.. [F|HeadArgs],
    append(Args,InnerArgs0,InnerArgs),
    Inner =.. [G|InnerArgs],
    append(Args,RecursiveArgs0,RecursiveArgs),
    Recursive =.. [F|RecursiveArgs].
			 

