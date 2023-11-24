 /*************************************************************************
 *									 *
 *	 YAP Prolog 							 *
 *									 *
 *	Yap Prolog was developed at NCCUP - Universidade do Porto	 *
 *									 *
 * Copyright L.Damas, V.S.Costa and Universidade do Porto 1985-1997	 *
 *									 *
 **************************************************************************
 *									 *
 * File:		exec.c *
 * Last rev:	8/2/88							 *
 * mods: *
 * comments:	Execute Prolog code					 *
 *									 *
 *************************************************************************/



#ifdef SCCS
static char SccsId[] = "@(#)cdmgr.c	1.1 05/02/98";
#endif

#include "absmi.h"

#include "amidefs.h"

#include "attvar.h"
#include "cut_c.h"
#include "yapio.h"
#include "heapgc.h"


/**
 * remove choice points created since a call to top-goal.
 *
 */
static void prune_inner_computation(choiceptr parent)
{
  CACHE_REGS
  /* code */
  choiceptr cut_pt;
  yamop *oP = P, *oCP = CP;
  Int oENV = LCL0 - ENV;

  cut_pt = B;
  while (cut_pt->cp_b && cut_pt->cp_b < parent)
  {
    cut_pt = cut_pt->cp_b;
  }
#ifdef YAPOR
  CUT_prune_to(cut_pt);
#endif
  B = cut_pt;
  Yap_TrimTrail();
  LOCAL_AllowRestart = FALSE;
  P = oP;
  CP = oCP;
  ENV = LCL0 - oENV;
  B = parent;
}

static bool set_watch(Int Bv, Term task)
{
  CACHE_REGS

    Term t = Yap_AllocExternalDataInStack(2);
  if (t == TermNil)
    return false;
  RepAppl(t)[1] = (CELL)setup_call_catcher_cleanup_tag;
  RepAppl(t)[2] =  Bv;
  *HR++ = t;
  *HR++ = task;
  TrailTerm(TR) = AbsPair(HR - 2);
  TrailVal(TR) = 0;
  TR++;
  return true;
}

static bool watch_cut(Term ext)
{
  CACHE_REGS
    // called after backtracking..
    //
    Term task = TailOfTerm(ext);
  Term cleanup = ArgOfTerm(3, task);
  Term e = 0;
  bool active = ArgOfTerm(5, task) == TermTrue;
  bool ex_mode = false;
    {
      return true;
    }
  CELL *port_pt = deref_ptr(RepAppl(task) + 2);
  CELL *completion_pt = deref_ptr(RepAppl(task) + 4);
  if ((ex_mode = Yap_HasException(PASS_REGS1)))
    {

      e = MkAddressTerm(LOCAL_ActiveError);
      Term t;
      if (active)
	{
	  t = Yap_MkApplTerm(FunctorException, 1, &e);
	}
      else
	{
	  t = Yap_MkApplTerm(FunctorExternalException, 1, &e);
	}
      port_pt[0] = t;
      completion_pt[0] = TermException;
    }
  else
    {
      port_pt[0] = TermCut;
    }
  yap_error_descriptor_t *old, *new;
  if (Yap_PeekException()) {
      old = LOCAL_ActiveError;
      LOCAL_ActiveError = new = malloc(sizeof( yap_error_descriptor_t ));
      Yap_ResetException(new);
  }
  Yap_exists(cleanup, true PASS_REGS);
  RESET_VARIABLE(port_pt);
  if (ex_mode) {
    free(new);
    LOCAL_ActiveError = old;
    LOCAL_PrologMode  |=   InErrorMode;
  }
  return true;
}

/**
 * external backtrack to current stack frame: call method
 * and control backtracking.
 *
 * @param  USES_REGS1                 [env for threaded execution]
 * @return                       c
 */
static bool watch_retry(Term d0 )
{
  CACHE_REGS
    // called after backtracking..
    //
    Term task = TailOfTerm(d0);
  bool box = ArgOfTerm(1, task) == TermTrue;
  Term cleanup = ArgOfTerm(3, task);
  bool complete = !IsVarTerm(ArgOfTerm(4, task));
  choiceptr B0 = (choiceptr)(LCL0 - IntegerOfTerm(ArgOfTerm(6, task)));
  yap_error_descriptor_t *old, *new;
  if (complete)
    return true;
  CELL *port_pt = deref_ptr(RepAppl(Deref(task)) + 2);
  CELL *complete_pt = deref_ptr(RepAppl(Deref(task)) + 4);
  Term t;
  bool ex_mode = false;

  // just do the simplest
  if ((ex_mode = Yap_HasException(PASS_REGS1)))
    {
      old = LOCAL_ActiveError;
      LOCAL_ActiveError = new = malloc(sizeof( yap_error_descriptor_t ));
      Yap_ResetException(new);
    }
  if (B >= B0)
    {
      t = TermFail;
      complete_pt[0] = t;
    }
  else if (box)
    {
      t = TermRedo;
    }
  else
    {
      return true;
    }
  port_pt[0] = t;
  Yap_exists(cleanup, true PASS_REGS);
  RESET_VARIABLE(port_pt);

  // Yap_PutException(e);
  if (ex_mode) {
    free(new);
    LOCAL_ActiveError = old;
    LOCAL_PrologMode  |=   InErrorMode;
    P = FAILCODE;
    return false;
  }
  if ( Yap_HasException(PASS_REGS1)) {
    P = FAILCODE;
    return false;
  }
  return true ;
}

/**
 * First call to non deterministic predicate. Just leaves a choice-point
 * hanging about for the future.
 *
 * @param  USES_REGS1    [env for threaded execution]
 * @return               [always succeed]
 */

static Int setup_call_catcher_cleanup(USES_REGS1)
{
  Term Setup = Deref(ARG1);
  choiceptr B0 = B;
  yamop *oP = P, *oCP = CP;
  Int oENV = LCL0 - ENV;
  Int oYENV = LCL0 - YENV;
  bool rc;

  Yap_DisableInterrupts(worker_id);
  rc = Yap_RunTopGoal(Setup, true);
  Yap_EnableInterrupts(worker_id);

  if (Yap_RaiseException())
    {
      return false;
    }
  if (!rc)
    {
      Yap_fail_all(B0 PASS_REGS);
      // We'll pass it throughs

      return false;
    }
  else
    {
      prune_inner_computation(B0);
    }
  P = oP;
  CP = oCP;
  ENV = LCL0 - oENV;
  YENV = LCL0 - oYENV;
  return rc;
}

static Int tag_cleanup(USES_REGS1)
{
  Int iB = LCL0 - (CELL *)B;
  set_watch(iB, Deref(ARG2));
  return Yap_unify(ARG1, MkIntegerTerm(iB));
}

static Int cleanup_on_exit(USES_REGS1)
{
  choiceptr B0 = (choiceptr)(LCL0 - IntegerOfTerm(Deref(ARG1)));
  Term task = Deref(ARG2);
  Term cleanup = ArgOfTerm(3, task);
  Term complete = IsNonVarTerm(ArgOfTerm(4, task));
  if (!Yap_dispatch_interrupts( PASS_REGS1 ))
    return false;



  while (B && (
	       B->cp_ap->opc == FAIL_OPCODE ||
	       B->cp_ap == TRUSTFAILCODE 
	       ))
    B = B->cp_b;
  if (complete)
    {
      return true;
    }
  CELL *catcher_pt = deref_ptr(RepAppl(Deref(task)) + 2);
  CELL *complete_pt = deref_ptr(RepAppl(Deref(task)) + 4);
  if (B < B0)
    {
      // non-deterministic
      set_watch(LCL0 - (CELL *)B, task);
       Yap_unify(catcher_pt[0], TermAnswer);
    }
  else
    {
      catcher_pt[0] = TermExit;
      complete_pt[0] = TermExit;
    }
  Yap_exists(cleanup, true PASS_REGS);
  if (Yap_HasException(PASS_REGS1))
    {
      Yap_JumpToEnv();
      return false;
    }
  return true;
}

static bool complete_ge(bool out, Term omod, yhandle_t sl, bool creeping)
{
  CACHE_REGS
    if (creeping)
      {
	Yap_signal(YAP_CREEP_SIGNAL);
      }
  CurrentModule = omod;
  Yap_CloseSlots(sl);
  return out;
}

static Int _user_expand_goal(USES_REGS1)
{
  yhandle_t sl = Yap_StartSlots();
  Int creeping = Yap_get_signal(YAP_CREEP_SIGNAL);
  PredEntry *pe;
  Term cmod = CurrentModule;
  Term g = Deref(ARG1);
   if (IsVarTerm(g))
    return false;
 yhandle_t h1 = Yap_InitSlot(g),
    h2 = Yap_InitSlot(ARG2);
  /* CurMod:goal_expansion(A,B) */
  if ((pe = RepPredProp(Yap_GetPredPropByFunc(FunctorGoalExpansion2, cmod))) &&
      pe->OpcodeOfPred != FAIL_OPCODE  &&
      pe->OpcodeOfPred != UNDEF_OPCODE  &&
      Yap_execute_pred(pe, NULL, true PASS_REGS))
    {
      return complete_ge( true, cmod, sl, creeping);
    }
  if (Yap_HasException(PASS_REGS1)){ // if (throw) {
      //  Yap_JumpToEnv();
    Yap_ResetException(NULL);
  }

  /* user:goal_expansion(A,B) */
  ARG1 = Yap_GetFromSlot(h1);
  ARG2 = Yap_GetFromSlot(h2);
  if ((pe = RepPredProp(
			Yap_GetPredPropByFunc(FunctorGoalExpansion2, USER_MODULE))) &&
      pe->OpcodeOfPred != UNDEF_OPCODE  &&
      pe->OpcodeOfPred != FAIL_OPCODE &&
      Yap_execute_pred(pe, NULL, true PASS_REGS))
    {
      return complete_ge( true, cmod, sl, creeping);
    }
  if (Yap_HasException(PASS_REGS1))  { // if (throw) {
      //  Yap_JumpToEnv();
    Yap_ResetException(NULL);
  }
  /* user:goal_expansion(A,CurMod,B) */
  ARG1 = Yap_GetFromSlot(h1);
  ARG2 = cmod;
  ARG3 = Yap_GetFromSlot(h2);
  if ((pe = RepPredProp(
			Yap_GetPredPropByFunc(FunctorGoalExpansion, USER_MODULE))) &&
      pe->OpcodeOfPred != FAIL_OPCODE &&
      pe->OpcodeOfPred != UNDEF_OPCODE  &&
      Yap_execute_pred(pe, NULL, true PASS_REGS))
    {
      return complete_ge( true, cmod, sl, creeping);
    }
  if (Yap_HasException(PASS_REGS1)){ // if (throw) {
      //  Yap_JumpToEnv();
    Yap_ResetException(NULL);
  }

  ARG1 = Yap_GetFromSlot(h1);
  ARG2 = Yap_GetFromSlot(h2);
  if ((pe = RepPredProp(
			Yap_GetPredPropByFunc(FunctorGoalExpansion2, SYSTEM_MODULE))) &&
      pe->OpcodeOfPred != UNDEF_OPCODE  &&
      pe->OpcodeOfPred != FAIL_OPCODE &&
      Yap_execute_pred(pe, NULL, true PASS_REGS))
    {
      return complete_ge( true, cmod, sl, creeping);
    }
  return  complete_ge(false, cmod, sl, creeping);
}


static Int do_term_expansion(USES_REGS1)
{
  yhandle_t sl = Yap_StartSlots();
  Int creeping = Yap_get_signal(YAP_CREEP_SIGNAL);
  PredEntry *pe;
  Term cmod = CurrentModule, omod = cmod;
  Term g = Deref(ARG1), o = Deref(ARG2);
  yhandle_t h1 = Yap_InitSlot(g), h2 = Yap_InitSlot(o);
  /* user:term_expansion(A,B) */
  if ((pe = RepPredProp(
			Yap_GetPredPropByFunc(FunctorTermExpansion, USER_MODULE))) &&
      pe->OpcodeOfPred != FAIL_OPCODE && pe->OpcodeOfPred != UNDEF_OPCODE &&
      Yap_execute_pred(pe, NULL, true PASS_REGS))
    {
      return complete_ge(true, omod, sl, creeping);
    }
  ARG1 =
    Yap_GetFromSlot(h1);
  ARG2 = cmod;
  ARG3 =  Yap_GetFromSlot(h2);
  if ((pe = RepPredProp(
			Yap_GetPredPropByFunc(FunctorTermExpansion3, USER_MODULE))) &&
      pe->OpcodeOfPred != FAIL_OPCODE && pe->OpcodeOfPred )
    {

      return complete_ge(true, omod, sl, creeping);

    }
  /* CurMod:term_expansion(A,B) */
  ARG1 =   Yap_GetFromSlot(h1);
  ARG2 =  Yap_GetFromSlot(h2);
  if (cmod != USER_MODULE &&
      (pe = RepPredProp(Yap_GetPredPropByFunc(FunctorTermExpansion, cmod))) &&
      pe->OpcodeOfPred != FAIL_OPCODE && pe->OpcodeOfPred != UNDEF_OPCODE &&
      Yap_execute_pred(pe, NULL, true PASS_REGS))
    {

      return complete_ge(true, omod, sl, creeping);
    }
  /* system:term_expansion(A,B) */
  ARG1 =   Yap_GetFromSlot(h1);
  ARG2 =  Yap_GetFromSlot(h2);
  if ((pe = RepPredProp(
			Yap_GetPredPropByFunc(FunctorTermExpansion, SYSTEM_MODULE))) &&
      pe->OpcodeOfPred != FAIL_OPCODE &&
      pe->OpcodeOfPred != UNDEF_OPCODE &&
      Yap_execute_pred(pe, NULL, true PASS_REGS))
    {
      return complete_ge(true, omod, sl, creeping);
    }

  return complete_ge(
		     false , omod, sl, creeping);
}

void Yap_InitExecStruct(void)
{
  YAP_opaque_handler_t catcher_ops;
  memset(&catcher_ops, 0, sizeof(catcher_ops));
  catcher_ops.cut_handler = watch_cut;
  catcher_ops.fail_handler = watch_retry;
  setup_call_catcher_cleanup_tag = YAP_NewOpaqueType(&catcher_ops);
   Yap_InitCPred("$do_user_expansion", 2, _user_expand_goal, 0);
  Yap_InitCPred("$do_term_expansion", 2, do_term_expansion, 0);
  Yap_InitCPred("$tag_cleanup", 2, tag_cleanup, 0);
  Yap_InitCPred("$setup_call_catcher_cleanup", 1, setup_call_catcher_cleanup,
                0);
  Yap_InitCPred("$cleanup_on_exit", 2, cleanup_on_exit, 0);
}
